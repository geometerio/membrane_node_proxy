defmodule Membrane.NodeProxy.Buffer do
  @moduledoc false
  require Membrane.Logger

  @spec parse(data :: binary()) :: any()
  def parse(<<packet::binary()>>) do
    case deserialize(packet) do
      {:ok, payload} ->
        {:ok, payload}

      :error ->
        Membrane.Logger.warn("unable to deserialize packet")
        {:ok, []}
    end
  end

  @spec serialize(any()) :: binary()
  def serialize(buffer) do
    :erlang.term_to_binary(buffer, compressed: 1, minor_version: 2)
  end

  defp deserialize(packet) do
    {:ok, :erlang.binary_to_term(packet)}
  rescue
    _ ->
      :error
  end
end
