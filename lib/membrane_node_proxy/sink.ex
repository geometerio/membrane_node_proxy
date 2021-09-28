defmodule Membrane.NodeProxy.Sink do
  @moduledoc """
  Element which can send buffers to other nodes.
  """
  use Membrane.Sink
  alias Membrane.NodeProxy.Buffer
  alias Membrane.NodeProxy.Config
  alias Membrane.NodeProxy.Inet
  alias Membrane.NodeProxy.SourceReadyEvent
  require Membrane.Logger

  def_input_pad :input, caps: :any, demand_unit: :buffers
  def_input_pad :data_channel, caps: :any, availability: :on_request, mode: :push

  defmodule SourceAddress do
    @moduledoc false
    @type t() :: %__MODULE__{}
    defstruct addresses: [],
              mtu: nil,
              preferred_addr: nil,
              port: nil
  end

  defmodule State do
    @moduledoc false
    @type t() :: %__MODULE__{}
    @enforce_keys [:socket]
    defstruct enabled?: false,
              global_mtu: nil,
              remote_sources: %{},
              socket: nil
  end

  @impl true
  def handle_init(_opts) do
    {:ok, socket} =
      if Config.supports_inet_socket?(),
        do: :gen_udp.open(0, [{:inet_backend, :socket}, :binary]),
        else: :gen_udp.open(0, [:binary])

    {:ok, %State{socket: socket}}
  end

  @impl true
  def handle_pad_added(Pad.ref(:data_channel, source_id), _ctx, state) do
    ### source was started on a remote endpoint
    Membrane.Logger.debug("data channel pad added for #{inspect(source_id)}")
    {:ok, state}
  end

  @impl true
  def handle_pad_removed(Pad.ref(:data_channel, source_id), _ctx, state) do
    ### source was stopped or crashed on a remote endpoint
    Membrane.Logger.debug("data channel pad removed for #{inspect(source_id)}")
    remote_sources = Map.delete(state.remote_source, source_id)
    enabled? = remote_sources != %{}
    {:ok, %{state | remote_sources: remote_sources, enabled?: enabled?}}
  end

  @impl true
  def handle_prepared_to_playing(_context, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_event(Pad.ref(:data_channel, source_id), %SourceReadyEvent{} = event, _ctx, state) do
    remote_source = %SourceAddress{addresses: event.addresses, port: event.port}
    remote_sources = Map.put(state.remote_sources, source_id, remote_source)

    for address <- remote_source.addresses do
      :gen_udp.send(
        state.socket,
        Keyword.fetch!(address, :addr),
        remote_source.port,
        "syn:" <> source_id
      )
    end

    {:ok, %{state | remote_sources: remote_sources}}
  end

  def handle_event(_pad, _event, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_other({:udp, _port, ip, _remote_port, "ack:" <> source_id}, _ctx, state) do
    remote_source =
      state.remote_sources[source_id]
      |> add_preferred_addr(ip)
      |> add_mtu(ip)

    global_mtu =
      if state.global_mtu,
        do: Enum.min(state.global_mtu, remote_source.mtu),
        else: remote_source.mtu

    {:ok,
     %{
       state
       | enabled?: true,
         global_mtu: global_mtu,
         remote_sources: Map.put(state.remote_sources, source_id, remote_source)
     }}
  end

  @impl true
  def handle_write_list(:input, buffers, _cxt, %{enabled?: false} = state),
    do: {{:ok, demand: {:input, length(buffers)}}, state}

  def handle_write_list(:input, buffers, ctx, state) do
    packet = Buffer.serialize(buffers)

    if byte_size(packet) < state.global_mtu do
      for {_source_id, remote} <- state.remote_sources,
          !is_nil(remote.preferred_addr) do
        :gen_udp.send(state.socket, remote.preferred_addr, remote.port, packet)
      end
    else
      Membrane.Logger.warn("buffer list exceeds MTU, sending individual packets")

      for buffer <- buffers do
        handle_write(:input, buffer, ctx, state)
      end
    end

    {{:ok, demand: {:input, length(buffers)}}, state}
  end

  @impl true
  def handle_write(:input, _buffer, _cxt, %{enabled?: false} = state),
    do: {{:ok, demand: :input}, state}

  def handle_write(:input, %Membrane.Buffer{} = buffer, _ctx, state) do
    packet = Buffer.serialize(buffer)

    for {_source_id, remote} <- state.remote_sources,
        !is_nil(remote.preferred_addr) and !is_nil(remote.mtu) do
      :gen_udp.send(state.socket, remote.addr, remote.port, packet)
    end

    {{:ok, demand: :input}, state}
  end

  defp add_preferred_addr(%SourceAddress{preferred_addr: nil} = source, addr),
    do: %{source | preferred_addr: addr}

  defp add_preferred_addr(source, _addr), do: source

  @spec add_mtu(SourceAddress.t(), Inet.inet_addr()) :: SourceAddress.t()
  def add_mtu(remote_source, ip) do
    case remote_source do
      %{mtu: nil} = source ->
        mtu =
          source.addresses
          |> Enum.find_value(fn
            [addr: ^ip, mtu: mtu] ->
              mtu

            _addr ->
              nil
          end)

        %{source | mtu: mtu}

      _source ->
        remote_source
    end
  end
end
