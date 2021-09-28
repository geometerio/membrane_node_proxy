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
    if Application.get_env(:membrane_node_proxy, :use_inet_socket?) |> is_nil() do
      with {:ok, libraries} <- libs(),
           {:ok, kernel} <- libraries |> kernel_version() do
        Application.put_env(:membrane_node_proxy, :use_inet_socket?, supports_socket?(kernel))
      else
        _error ->
          Application.put_env(:membrane_node_proxy, :use_inet_socket?, false)
      end
    end

    :ok
  end

  defp supports_socket?(kernel_version) do
    normalized_version =
      case String.split(kernel_version, ".") do
        [_major, _minor] -> kernel_version <> ".0"
        [_major] -> kernel_version <> ".0.0"
        _other -> kernel_version
      end

    Version.match?(normalized_version, ">= 8.1.0")
  end

  defp kernel_version(["kernel-" <> version | _rest]),
    do: {:ok, version}

  defp kernel_version([]),
    do: {:error, :enoent}

  defp kernel_version([_ | rest]),
    do: kernel_version(rest)

  defp libs(),
    do:
      :code.root_dir()
      |> Path.join("lib")
      |> File.ls()
end
