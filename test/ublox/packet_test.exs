defmodule PacketTest do
  use ExUnit.Case
  alias Rabbit.Ublox.Packet

  test "builds a packet" do
    packet = %Packet{
      class: :cfg,
      id: :rate,
      payload: [
        # The elapsed time between GNSS measurements,
        <<100::16-little>>,

        # The ratio between the number of measurements and the number of navigation solutions,
        # e.g. 5 means five measurements for every navigation solution.
        <<1::16-little>>,

        # The time system to which measurements are aligned: 0: UTC time 1: GPS time
        <<1::16-little>>
      ]
    }

    assert Packet.encode(packet) == <<0xB5,0x62,0x06,0x08,0x06,0x00,0x64,0x00,0x01,0x00,0x01,0x00,0x7A,0x12>>
  end

  test "shortcut" do
    packet = Packet.p(:cfg, :rate, [<<100::16-little, 1::16-little, 1::16-little>>])
    assert Packet.encode(packet) == <<0xB5,0x62,0x06,0x08,0x06,0x00,0x64,0x00,0x01,0x00,0x01,0x00,0x7A,0x12>>
  end

end
