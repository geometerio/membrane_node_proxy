defmodule Membrane.NodeProxy do
  @moduledoc """
  Provides a mechanism for sending buffers between two nodes.
  """
  use Application
  alias Membrane.NodeProxy.Config

  @doc false
  @impl true
  def start(_start_type, _start_args) do
    Config.update()
    Supervisor.start_link([], strategy: :one_for_one)
  end

  @impl true
  def config_change(_changed, _new, _removed) do
    Config.update()
  end
end
