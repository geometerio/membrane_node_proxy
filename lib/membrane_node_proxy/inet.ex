defmodule Membrane.NodeProxy.Inet do
  @moduledoc false

  @type attr_map() :: %{charlist() => [addr: inet_addr(), attributes: [mtu: integer()]]}
  @type inet_addr() :: {integer(), integer(), integer(), integer()}
  @type if_map() :: %{charlist() => inet_addr()}

  @spec private_addresses() :: {:ok, if_map()}
  def private_addresses() do
    {:ok, interfaces} = :net.getifaddrs(:inet)
    private_addresses(interfaces)
  end

  @spec private_addresses([:net.ifaddrs()]) :: {:ok, if_map()}
  def private_addresses(interfaces) do
    addresses =
      interfaces
      |> Enum.reduce(%{}, fn
        %{name: name, addr: %{addr: {10, _, _, _} = interface}}, acc ->
          acc |> Map.put(name, interface)

        %{name: name, addr: %{addr: {192, 168, _, _} = interface}}, acc ->
          acc |> Map.put(name, interface)

        %{name: name, addr: %{addr: {172, block, _, _} = interface}}, acc when block in 16..31 ->
          acc |> Map.put(name, interface)

        _if, acc ->
          acc
      end)

    {:ok, addresses}
  end

  @spec merge_attributes(if_map()) :: {:ok, attr_map()}
  def merge_attributes(if_map) do
    attr_map =
      for {interface, addr} <- if_map, into: %{} do
        {:ok, attributes} = :inet.ifget(interface, [:mtu])
        {interface, [addr: addr, attributes: attributes]}
      end

    {:ok, attr_map}
  end
end
