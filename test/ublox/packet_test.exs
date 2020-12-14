defmodule PacketTest do
  use ExUnit.Case
  alias Rabbit.Ublox.Packet
  alias Rabbit.Units

  test "it performs a checksum correctly" do
    assert Packet.checksum_for(<<0x06,0x01,0x08,0x00,0xF0,0x00,0x00,0x00,0x00,0x00,0x00,0x01>>) == <<0x00,0x24>>
    assert Packet.checksum_for(<<0x06,0x01,0x08,0x00,0xF0,0x01,0x00,0x00,0x00,0x00,0x00,0x01>>) == <<0x01,0x2B>>
  end

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

  test "decodes a packet" do
    raw = <<181, 98, 1, 7, 92, 0, 128, 27, 136, 4, 228, 7, 12, 13, 21, 6, 50, 55,
     10, 0, 0, 0, 67, 54, 172, 47, 3, 1, 10, 9, 9, 138, 109, 206, 149, 149, 89,
     25, 121, 158, 2, 0, 186, 38, 3, 0, 82, 11, 0, 0, 109, 14, 0, 0, 225, 255,
     255, 255, 212, 255, 255, 255, 40, 0, 0, 0, 53, 0, 0, 0, 2, 228, 132, 0, 57,
     1, 0, 0, 72, 18, 60, 0, 195, 0, 0, 0, 224, 74, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     28, 176>>

    { :ok, packet } = Packet.decode(raw)

    assert packet.class == 0x01
    assert packet.id == 0x07
  end

  test "testing nav_pvt" do
    raw = <<181, 98, 1, 7, 92, 0, 212, 18, 106, 4, 228, 7, 12, 13, 20, 34, 2,
     55, 6, 0, 0, 0, 65, 245, 205, 29, 3, 1, 10, 11, 15, 138, 109, 206, 9, 151,
     89, 25, 75, 187, 2, 0, 140, 67, 3, 0, 55, 7, 0, 0, 98, 10, 0, 0, 2, 0, 0, 0,
     17, 0, 0, 0, 5, 0, 0, 0, 17, 0, 0, 0, 231, 20, 67, 1, 0, 1, 0, 0, 175, 246,
     72, 0, 160, 0, 0, 0, 224, 74, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 63,>>

    { :ok, packet } = Packet.decode(raw)

    # assert packet.class == 0x01
    # assert packet.id == 0x07
    <<
      itow::little-little-integer-size(32),
      year::little-little-integer-size(16),

      month,
      day,
      hour,
      min,
      sec,

      # # valid,
      valid,

      time_accuracy::little-integer-size(32),

      nanoseconds::little-signed-integer-size(32),

      # 0: no fix
      # 1: dead reckoning only
      # 2: 2D-fix
      # 3: 3D-fix
      # 4: GNSS + dead reckoning combined 5: time only fix
      fix_type,

      flags,
      flags2,

      satellites_used,

      longitude::little-signed-integer-size(32),
      latitude::little-signed-integer-size(32),
      height::little-signed-integer-size(32),
      height_above_sea_level::little-signed-integer-size(32),

      horizontal_accuracy::little-integer-size(32),
      vertical_accuracy::little-integer-size(32),

      velocity_north::little-signed-integer-size(32),
      velocity_east::little-signed-integer-size(32),
      velocity_down::little-signed-integer-size(32),

      ground_speed::little-signed-integer-size(32),
      heading_of_motion::little-signed-integer-size(32),

      speed_accuracy::little-integer-size(32),
      heading_accuracy::little-integer-size(32),

      _position_dop::16,
      flags3,
      _reserved::integer-size(40),

      vehicle_heading::little-signed-integer-size(32),

      x::binary
    >> = packet.payload

    IO.inspect(%{
      itow: itow,
      year: year,
      month: month,
      day: day,
      hour: hour,
      min: min,
      sec: sec,
      valid: valid,
      time_accuracy: time_accuracy,
      satellites_used: satellites_used,
      fix_type: fix_type,
      longitude: longitude / :math.pow(10, 7),
      latitude: latitude / :math.pow(10, 7),
      height: Units.mm_to_foot(height),
      height_above_sea_level: Units.mm_to_foot(height_above_sea_level),
      horizontal_accuracy: Units.mm_to_foot(horizontal_accuracy),
      vertical_accuracy: Units.mm_to_foot(vertical_accuracy),
      ground_speed: Units.mm_to_foot(ground_speed),
      # vehicle_heading: vehicle_heading,
    })
  end

end
