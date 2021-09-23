defmodule Membrane.NodeProxy.Sink do
  @moduledoc """
  Element which can send buffers to other nodes.
  """
  use Membrane.Sink
  alias Membrane.NodeProxy.Buffer
  alias Membrane.NodeProxy.SourceReadyEvent
  require Membrane.Logger

  def_input_pad :input, caps: :any, demand_unit: :buffers
  def_input_pad :data_channel, caps: :any, availability: :on_request, mode: :push

  defmodule SourceAddress do
    @moduledoc false
    defstruct interfaces: nil,
              preferred_addr: nil,
              port: nil
  end

  @impl true
  def handle_init(_opts) do
    {:ok, socket} = :gen_udp.open(0, [:binary])
    {:ok, %{remote_sources: %{}, socket: socket}}
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
    {:ok, state}
  end

  @impl true
  def handle_prepared_to_playing(_context, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_event(Pad.ref(:data_channel, source_id), %SourceReadyEvent{} = event, _ctx, state) do
    remote_source = %SourceAddress{interfaces: event.interfaces, port: event.port}
    remote_sources = Map.put(state.remote_sources, source_id, remote_source)

    for interface <- remote_source.interfaces do
      :gen_udp.send(state.socket, interface, remote_source.port, "ping:" <> source_id)
    end

    {:ok, %{state | remote_sources: remote_sources}}
  end

  def handle_event(_pad, _event, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_other({:udp, _port, ip, _remote_port, "pong:" <> source_id}, _ctx, state) do
    remote_source = Map.put(state.remote_sources[source_id], :preferred_addr, ip)
    {:ok, %{state | remote_sources: Map.put(state.remote_sources, source_id, remote_source)}}
  end

  @impl true
  def handle_write_list(:input, buffers, _ctx, state) do
    packet = Buffer.serialize(buffers)

    for {_source_id, remote} <- state.remote_sources do
      if remote.preferred_addr,
        do: :gen_udp.send(state.socket, remote.preferred_addr, remote.port, packet)
    end

    {{:ok, demand: {:input, length(buffers)}}, state}
  end

  @impl true
  def handle_write(:input, %Membrane.Buffer{} = buffer, _ctx, state) do
    packet = Buffer.serialize(buffer)

    for {_source_id, remote} <- state.remote_sources do
      :gen_udp.send(state.socket, remote.addr, remote.port, packet)
    end

    {{:ok, demand: :input}, state}
  end
end
