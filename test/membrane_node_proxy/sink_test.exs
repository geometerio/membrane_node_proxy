defmodule Membrane.NodeProxy.SinkTest do
  use ExUnit.Case

  alias Membrane.NodeProxy.Sink

  describe "add_mtu" do
    test "returns the unchanged source address when mtu is already set" do
      assert %Sink.SourceAddress{
               addresses: [
                 [addr: {127, 0, 0, 1}, mtu: 1500],
                 [addr: {10, 0, 0, 2}, mtu: 1600]
               ],
               port: 0,
               mtu: 12,
               preferred_addr: {127, 0, 0, 1}
             }
             |> Sink.add_mtu({127, 0, 0, 1}) == %Sink.SourceAddress{
               addresses: [
                 [addr: {127, 0, 0, 1}, mtu: 1500],
                 [addr: {10, 0, 0, 2}, mtu: 1600]
               ],
               port: 0,
               mtu: 12,
               preferred_addr: {127, 0, 0, 1}
             }
    end

    test "sets the mtu when not already set" do
      assert %Sink.SourceAddress{
               addresses: [
                 [addr: {127, 0, 0, 1}, mtu: 1500],
                 [addr: {10, 0, 0, 2}, mtu: 1600]
               ],
               port: 0,
               mtu: nil,
               preferred_addr: {127, 0, 0, 1}
             }
             |> Sink.add_mtu({127, 0, 0, 1}) == %Sink.SourceAddress{
               addresses: [
                 [addr: {127, 0, 0, 1}, mtu: 1500],
                 [addr: {10, 0, 0, 2}, mtu: 1600]
               ],
               port: 0,
               mtu: 1500,
               preferred_addr: {127, 0, 0, 1}
             }

      assert %Sink.SourceAddress{
               addresses: [
                 [addr: {127, 0, 0, 1}, mtu: 1500],
                 [addr: {10, 0, 0, 2}, mtu: 1600]
               ],
               port: 0,
               mtu: nil,
               preferred_addr: {127, 0, 0, 1}
             }
             |> Sink.add_mtu({10, 0, 0, 2}) == %Sink.SourceAddress{
               addresses: [
                 [addr: {127, 0, 0, 1}, mtu: 1500],
                 [addr: {10, 0, 0, 2}, mtu: 1600]
               ],
               port: 0,
               mtu: 1600,
               preferred_addr: {127, 0, 0, 1}
             }
    end
  end
end
