defmodule Membrane.NodeProxy.Config do
  @moduledoc """
  Provides functions for getting or setting application configuration
  for Membrane.NodeProxy.
  """
  @spec supports_inet_socket?() :: boolean()
  def supports_inet_socket?() do
    Application.get_env(:membrane_node_proxy, :use_inet_socket?, false)
  end

  @spec update() :: :ok
  def update() do
    if Application.get_env(:membrane_node_proxy, :use_inet_socket?) |> is_nil(),
      do: Application.put_env(:membrane_node_proxy, :use_inet_socket?, supports_socket?())

    :ok
  end

  defp supports_socket?(), do: Code.ensure_loaded?(:gen_udp_socket)
end
