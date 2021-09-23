defmodule Membrane.NodeProxy.SourceReadyEvent do
  @moduledoc """
  An event for a Source to notify a Sink that it is ready to receive data, with
  information for how to message it.
  """
  @derive Membrane.EventProtocol
  defstruct [
    :addresses,
    :port,
    :node
  ]
end
