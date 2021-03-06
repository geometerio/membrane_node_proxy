defmodule Membrane.NodeProxy.Source do
  @moduledoc """
  Element which can receive buffers from other nodes.
  """
  use Membrane.Source
  alias Membrane.NodeProxy.Buffer
  alias Membrane.NodeProxy.Config
  alias Membrane.NodeProxy.Inet
  alias Membrane.NodeProxy.SourceReadyEvent
  require Membrane.Logger

  def_output_pad :output, caps: :any, availability: :on_request, mode: :push
  def_output_pad :data_channel, caps: :any, mode: :push

  defmodule State do
    @moduledoc false
    @enforce_keys [:port, :socket]
    defstruct addresses: %{}, port: nil, socket: nil
  end

  @impl true
  def handle_init(_opts) do
    with {:ok, addresses} <- Inet.private_addresses(),
         {:ok, addresses_with_attributes} <- Inet.merge_attributes(addresses),
         {:ok, socket} <- open_socket(),
         {:ok, port} <- :inet.port(socket) do
      Membrane.Logger.debug("starting track source on node #{node()}")
      {:ok, %State{addresses: addresses_with_attributes, port: port, socket: socket}}
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
           addresses: Map.values(state.addresses),
           node: node()
         }}}, state}
  end

  @impl true
  def handle_other({:udp, _port, ip, remote_port, "syn:" <> id}, _ctx, state) do
    :gen_udp.send(state.socket, ip, remote_port, "ack:" <> id)
    {:ok, state}
  end

  def handle_other({:udp, _port, _ip, _remote_port, data}, ctx, state) do
    {:ok, buffers} = Buffer.parse(data)

    actions =
      ctx.pads
      |> Enum.reduce([], fn
        {:data_channel, _pad}, acc ->
          acc

        {pad_name, _pad}, acc ->
          acc ++ [buffer: {pad_name, buffers}]
      end)

    {{:ok, actions}, state}
  end

  def handle_other({_port, :eof}, _ctx, state) do
    Membrane.Logger.warn("port died")
    # stop(self())
    {:ok, state}
  end

  defp open_socket() do
    if Config.supports_inet_socket?(),
      do: :gen_udp.open(0, [{:inet_backend, :socket}, :binary]),
      else: :gen_udp.open(0, [:binary])
  end
end
