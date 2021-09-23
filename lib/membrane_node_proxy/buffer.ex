defmodule Membrane.NodeProxy.Buffer do
  @moduledoc false

  @spec parse(data :: binary(), accumulator :: {length :: integer() | nil, buffer :: binary()}) ::
          any()
  def parse(<<packet::binary()>>, {length, buffer}) do
    {length, buffer <> packet, []}
    |> parse()
  end

  defp parse({nil, <<length::integer-size(4)-unit(8), packet::binary()>>, acc}),
    do: parse({length, packet, acc})

  defp parse({length, packet, acc}) when byte_size(packet) >= length do
    <<packet::binary-size(length), rest::binary()>> = packet
    parse({nil, rest, [deserialize(packet) | acc]})
  end

  defp parse({length, packet, acc}), do: {:ok, Enum.reverse(acc), {length, packet}}

  @spec serialize(any()) :: binary()
  def serialize(buffer) do
    payload = :erlang.term_to_binary(buffer, compressed: 1, minor_version: 2)
    <<byte_size(payload)::integer-size(4)-unit(8)>> <> payload
  end

  defp deserialize(packet) do
    :erlang.binary_to_term(packet)
  end
end
