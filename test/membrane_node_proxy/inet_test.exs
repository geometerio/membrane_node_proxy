defmodule Membrane.NodeProxy.InetTest do
  use ExUnit.Case

  alias Membrane.NodeProxy.Inet

  defp address(device, {addr, _broadcast, netmask}) do
    %{
      addr: %{addr: addr, family: :inet, port: 0},
      flags: [:up, :broadcast, :running, :multicast],
      name: device,
      netmask: %{addr: netmask, family: :inet, port: 0}
    }
  end

  describe "private_addresses" do
    test "includes RFC1918 private addresses" do
      assert [
               address('eth0', {{172, 16, 12, 77}, {172, 31, 255, 255}, {255, 240, 0, 0}}),
               address('eth1', {{172, 31, 12, 77}, {172, 31, 255, 255}, {255, 240, 0, 0}}),
               address('eth2', {{192, 168, 3, 3}, {192, 168, 255, 255}, {255, 255, 0, 0}}),
               address('eth3', {{10, 1, 1, 1}, {10, 255, 255, 255}, {255, 0, 0, 0}}),
               address('eth4', {{10, 255, 255, 254}, {10, 255, 255, 255}, {255, 0, 0, 0}})
             ]
             |> Inet.private_addresses() ==
               {:ok,
                %{
                  'eth0' => {172, 16, 12, 77},
                  'eth1' => {172, 31, 12, 77},
                  'eth2' => {192, 168, 3, 3},
                  'eth3' => {10, 1, 1, 1},
                  'eth4' => {10, 255, 255, 254}
                }}
    end

    test "filters localhost" do
      assert [
               address('lo0', {{127, 0, 0, 1}, :undefined, {255, 0, 0, 0}})
             ]
             |> Inet.private_addresses() ==
               {:ok, %{}}
    end

    test "filters public IP addresses" do
      assert [
               address('eth0', {{164, 12, 1, 1}, {255, 255, 255, 255}, {0, 0, 0, 0}}),
               address('eth1', {{192, 169, 3, 3}, {192, 169, 255, 255}, {255, 255, 0, 0}})
             ]
             |> Inet.private_addresses() ==
               {:ok, %{}}
    end

    test "filters link local addresses" do
      assert [
               address('eth0', {{169, 254, 1, 1}, {169, 254, 255, 255}, {255, 255, 0, 0}})
             ]
             |> Inet.private_addresses() ==
               {:ok, %{}}
    end
  end
end
