defmodule Membrane.NodeProxy.Inet do
  @moduledoc false

  @type ipv4_addr() :: {integer(), integer(), integer(), integer()}

  @spec private_addresses() :: [ipv4_addr()]
  def private_addresses() do
    {:ok, interfaces} = :inet.getif()

    interfaces
    |> Enum.reduce([], fn
      {{10, _, _, _} = interface, _, _}, acc ->
        [interface | acc]

      {{192, 168, _, _} = interface, _, _}, acc ->
        [interface | acc]

      {{172, block, _, _} = interface, _, _}, acc when block in 16..31 ->
        [interface | acc]

      _if, acc ->
        acc
    end)
  end
end
