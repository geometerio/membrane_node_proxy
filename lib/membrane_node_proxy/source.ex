defmodule Membrane.NodeProxy.Source do
  @moduledoc """
  Element which can receive buffers from other nodes.
  """
  use Membrane.Source
  alias Membrane.NodeProxy.Buffer
  alias Membrane.NodeProxy.Inet
  alias Membrane.NodeProxy.SourceReadyEvent
  require Membrane.Logger

  def_output_pad :output, caps: :any, availability: :on_request, mode: :push
  def_output_pad :data_channel, caps: :any, mode: :push

  defmodule State do
    @moduledoc false
    @enforce_keys [:port, :socket]
    defstruct port: nil, socket: nil, packet_buffer: {nil, <<>>}
  end

  @impl true
  def handle_init(_opts) do
    with {:ok, socket} <- :gen_udp.open(0, [:binary]),
         {:ok, port} <- :inet.port(socket) do
      Membrane.Logger.debug("starting track source on node #{node()}")
      {:ok, %State{port: port, socket: socket}}
    else
      {:error, error} ->
        Membrane.Logger.error("""
        Unable to start Membrane.NodeProxy.Source.
        Reason: #{inspect(error)}
        """)

        {:error, error}
    end
  end

  @impl true
  def handle_pad_added(Pad.ref(:output, ref), _ctx, state) do
    Membrane.Logger.debug("pad added #{inspect(ref)}")
    {:ok, state}
  end

  @impl true
  def handle_pad_removed(Pad.ref(:output, ref), _ctx, state) do
    Membrane.Logger.debug("pad removed #{inspect(ref)}")
    {:ok, state}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok,
      event:
        {:data_channel,
         %SourceReadyEvent{
           port: state.port,
           interfaces: Inet.private_addresses(),
           node: node()
         }}}, state}
  end

  @impl true
  def handle_other({:udp, _port, ip, remote_port, "syn:" <> id}, _ctx, state) do
    :gen_udp.send(state.socket, ip, remote_port, "ack:" <> id)
    {:ok, state}
  end

  def handle_other({:udp, _port, _ip, _remote_port, data}, ctx, state) do
    {:ok, buffers, packet_buffer} = Buffer.parse(data, state.packet_buffer)

    actions =
      ctx.pads
      |> Enum.reduce([], fn
        {:data_channel, _pad}, acc ->
          acc

        {pad_name, _pad}, acc ->
          acc ++ [buffer: {pad_name, buffers}]
      end)

    {{:ok, actions}, %{state | packet_buffer: packet_buffer}}
  end

  def handle_other({_port, :eof}, _ctx, state) do
    Membrane.Logger.warn("port died")
    # stop(self())
    {:ok, state}
  end
end
