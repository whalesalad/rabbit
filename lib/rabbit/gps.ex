defmodule Rabbit.GPS do
  alias Rabbit.Ublox.Packet
  alias Circuits.I2C

  @i2c_addr 0x42

  def fetch do
    {:ok, response} = I2C.read(get_ref, @i2c_addr, 200)
    IO.inspect(response, width: :infinity)
  end

  def get_version(ref) do
    data = Packet.encode(Packet.p(:mon, :ver, []))
    response_size = 160 + 9

    {:ok, response} = I2C.write_read(ref, @i2c_addr, data, response_size)

    cleaned = response
      |> :binary.bin_to_list
      |> Enum.drop_while(fn byte -> byte == 0xFF end)
      |> :binary.list_to_bin

    IO.inspect([:relevant, response, :cleaned, cleaned])

    <<0xB5, 0x62, msg_class, msg_id, msg_length::16-little, payload::binary>> = cleaned

    IO.inspect(%{
      msg_class: msg_class,
      msg_id: msg_id,
      msg_length: msg_length
    })

    # <<sw_version::bytes-size(30), hw_version::bytes-size(10), rest::binary>> = payload

    payload
    |> String.split(<<0>>, trim: true)
  end

  def get_port_configuration(ref) do
    data = Packet.encode(Packet.p(:cfg, :prt, []))
    response_size = 20 + 9

    {:ok, response} = I2C.write_read(ref, @i2c_addr, data, response_size)

    IO.inspect(%{ response: response })

    <<0xFF, 0xB5, 0x62, _msg_class, _msg_id, _msg_length::16-little, payload::bytes-size(20), _::binary>> = response

    <<
      port_id,
      _,
      thresh,
      pin::5,
      pol::1,
      en::0,
      mode::bytes-size(4),
      _::bytes-size(4),
      in_proto_mask::bytes-size(2),
      out_proto_mask::bytes-size(2),
      flags::bytes-size(2),
      _::bytes-size(2)
    >> = payload

    <<_, _, _, slave_addr::7, _::1>> = mode

    %{
      port_id: port_id,
      thresh: thresh,
      pin: pin,
      pol: pol,
      en: en,
      slave_addr: slave_addr,
      in_proto_mask: in_proto_mask,
      out_proto_mask: out_proto_mask,
      flags: flags
    }
  end

  def configure() do
    get_ref |> configure
  end

  def configure(ref) do
    commands = [
      # GxGGA off
      Packet.p(:cfg, :msg, [0xF0,0x00,0x00,0x00,0x00,0x00,0x00,0x01]),

      # GxGLL off
      Packet.p(:cfg, :msg, [0xF0,0x01,0x00,0x00,0x00,0x00,0x00,0x01]),

      # GxGSA off
      Packet.p(:cfg, :msg, [0xF0,0x02,0x00,0x00,0x00,0x00,0x00,0x01]),

      # GxGSV off
      Packet.p(:cfg, :msg, [0xF0,0x03,0x00,0x00,0x00,0x00,0x00,0x01]),

      # GxRMC off
      Packet.p(:cfg, :msg, [0xF0,0x04,0x00,0x00,0x00,0x00,0x00,0x01]),

      # GxVTG off
      Packet.p(:cfg, :msg, [0xF0,0x05,0x00,0x00,0x00,0x00,0x00,0x01]),

      # NAV-PVT ON
      Packet.p(:cfg, :msg, [0x01,0x07,0x01]),

      # Disable Unnecessary Channels?
      Packet.p(:cfg, :gnss, [
        0x00, # msgVer
        0xFF, # numTrkChHw
        0xFF, # numTrkChUse
        0x04, # numConfigBlocks below ->

        # gnssId, resTrkCh, maxTrkCh, reserved1,
        # flags::4 bytes: <<_, sigCfgMask, ..... enable::1>>
        #

        # GPS, on set L2C
        0x00, 0x10, 0xFF, 0x00,
        0x01, 0x10, 0x00, 0x01,

        # SBAS, on
        0x01, 0x10, 0xFF, 0x00,
        0x00, 0x01, 0x00, 0x01,

        # QZSS, off
        0x05, 0x00, 0x03, 0x00,
        0x00, 0x00, 0x00, 0x00,

        # GLONASS, off
        0x06, 0x08, 0xFF, 0x00,
        0x00, 0x00, 0x00, 0x00
      ]),

      # NAV-POSLLH ON
      # Packet.p(:cfg, :msg, [0x01,0x02,0x00,0x01,0x00,0x00,0x00,0x00]),

      # Rate 10Hz
      Packet.p(:cfg, :rate, [0x64,0x00,0x01,0x00,0x01,0x00])
    ]

    commands |> Enum.each(fn packet ->
      I2C.write(ref, @i2c_addr, Packet.encode(packet))

      # Simulating a 38400baud pace (or less),
      # otherwise commands are not accepted by the device.
      :timer.sleep(5)
    end)
  end

  def get_pvt do
    get_pvt(get_ref)
  end

  def get_pvt(ref) do
    # request = Packet.encode(Packet.p(:nav, :pvt, []))
    response_size = 92 + 9
    # response_size = 200

    # {:ok, response} = I2C.write_read(ref, @i2c_addr, request, response_size)
    {:ok, response} = I2C.read(ref, @i2c_addr, response_size)

    cleaned = response
      |> :binary.bin_to_list
      |> Enum.drop_while(fn byte -> byte == 0xFF end)
      |> :binary.list_to_bin

    <<0xB5, 0x62, msg_class, msg_id, msg_length::16-little, payload::bytes-size(92), _::binary>> = cleaned

    IO.inspect(%{
      cleaned: cleaned,
      payload: payload,
      msg_class: msg_class,
      msg_id: msg_id,
      msg_length: msg_length,
      length: byte_size(payload)
    })

    <<
      itow::little-integer-size(32),
      year::little-integer-size(16),

      month,
      day,
      hour,
      min,
      sec,

      # valid,
      _::4,
      valid_mag::1,
      valid_time::1,
      fully_resolved::1,
      valid_date::1,

      _time_accuracy::integer-size(32),
      _nanoseconds::signed-integer-size(32),

      fix_type,

      # Flags, one byte
      _flags,
      # carrier_phase_solution::2,
      # head_vehicle_valid::1,
      # power_save_mode::3,
      # differential_corrections_applied::1,
      # gnss_fix_ok::1,

      _flags2,

      # confirmed_available::1,
      # confirmed_date::1,
      # confirmed_time::1,

      satellites_used,

      # longitude::signed-integer-size(32),

      # latitude::signed-integer-size(32),

      x::binary
    >> = payload

    <<
      crap::size(184),
      longitude::little-signed-integer-size(32),
      latitude::little-signed-integer-size(32),
      h_accuracy::little-integer-size(32),
      v_accuracy::little-integer-size(32),
      _::binary
    >> = payload

    %{
      itow: itow,
      year: year,
      month: month,
      day: day,
      hour: hour,
      min: min,
      sec: sec,
      valid_mag: valid_mag,
      valid_time: valid_time,
      fully_resolved: fully_resolved,
      valid_date: valid_date,
      # time_accuracy: time_accuracy,
      # nanoseconds: nanoseconds,
      fix_type: fix_type,
      # carrier_phase_solution: carrier_phase_solution,
      # head_vehicle_valid: head_vehicle_valid,
      # power_save_mode: power_save_mode,
      # differential_corrections_applied: differential_corrections_applied,
      # gnss_fix_ok: gnss_fix_ok,

      # confirmed_available: confirmed_available,
      # confirmed_date: confirmed_date,
      # confirmed_time: confirmed_time,
      satellites_used: satellites_used,

      # 33, 117
      longitude: longitude / :math.pow(10, 7),
      latitude: latitude / :math.pow(10, 7),
      h_accuracy: mm_to_foot(h_accuracy),
      v_accuracy: mm_to_foot(v_accuracy)
    }
  end

  def mm_to_foot(mm) do
    mm * 0.00328084
  end

  def get_ref() do
    {:ok, ref} = I2C.open("i2c-1")
    ref
  end

  def foo() do
    get_ref
      |> get_pvt
      |> IO.inspect
  end
end
