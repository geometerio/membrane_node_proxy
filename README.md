# MembraneNodeProxy

This Membrane plugin provides a mechanism for starting and connecting sources and
sinks that span erlang nodes.

A `Membrane.NodeProxy.Sink` behaves like a
[fake](https://github.com/membraneframework/membrane_element_fake)
until the `:data_channel` output of a source is linked to it, at which point it
will negotiate via UDP to connect to the source. Only RFC1918 private addresses
are currently supported.

A `Membrane.NodeProxy.Source` is started on a specific node, and can serve like a
[tee](https://github.com/membraneframework/membrane_element_fake), receiving data
once on that node and forwarding that data to multiple elements. On `handle_init`,
a `Source` will open a UDP socket on a random port and notify any sinks.

Lifecycle:

- Start a `Membrane.NodeProxy.Sink` element via a `ParentSpec`, on a specific node.
- Link the output of an element to the sink, via a dynamic input pad: `Pad.ref(:input, ref)`.
- Start a `Membrane.NodeProxy.Source` element on a different node.
- Link the source to the input of one or more elements, via dynamic output pads,
  eg `Pad.ref(:output, ref)`.
- Link the `:data_channel` output pad of the source to the `Pad.ref(:data_channel, ref)`
  dynamic input pad of the sink.

## Installation

```elixir
def deps do
  [
    {:membrane_node_proxy, "~> 0.1.0"}
  ]
end
```
