defmodule Membrane.NodeProxy.SourceReadyEvent do
  @moduledoc """
  An event
  """
  @derive Membrane.EventProtocol
  defstruct [:port, :interfaces, :node]
end
