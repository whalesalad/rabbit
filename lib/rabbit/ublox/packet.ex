defmodule Rabbit.Ublox.Packet do
  alias __MODULE__
  use Bitwise

  defstruct class: nil,
            id: nil,
            payload: []

  def p(class, id, payload) do
    %Packet{class: class, id: id, payload: payload}
  end

  # https://en.wikipedia.org/wiki/Fletcher%27s_checksum
  def checksum_byte(byte, [a, b] = checksum) do
    a = ((a + byte) &&& 0xFF)
    b = ((b + a) &&& 0xFF)
    [a, b]
  end

  # https://en.wikipedia.org/wiki/Fletcher%27s_checksum
  def checksum_for(body) do
    body
    |> :binary.bin_to_list
    |> Enum.reduce([0, 0], &checksum_byte/2)
    |> :binary.list_to_bin
  end

  def encode(packet) do
    msg_class = classes(packet.class)
    msg_id = apply(Packet, packet.class, [packet.id])

    payload = :binary.list_to_bin(packet.payload)

    payload_length = byte_size(payload)

    prefix = <<0xB5, 0x62>>

    # The body is the portion of the message that is checksummed.
    body = <<msg_class, msg_id, payload_length::16-little>> <> :binary.list_to_bin(packet.payload)

    checksum = checksum_for(body)

    # Finally, here is our entire message!
    prefix <> body <> checksum
  end

  def classes() do
    %{
      nav: 0x01,  # Navigation Results Messages: Position, Speed, Time, Acceleration, Heading, DOP, SVs used
      rxm: 0x02,  # Receiver Manager Messages: Satellite Status, RTC Status
      inf: 0x04,  # Information Messages: Printf-Style Messages, with IDs such as Error, Warning, Notice
      ack: 0x05,  # Ack/Nak Messages: Acknowledge or Reject messages to UBX-CFG input messages
      cfg: 0x06,  # Configuration Input Messages: Set Dynamic Model, Set DOP Mask, Set Baud Rate, etc.
      upd: 0x09,  # Firmware Update Messages: Memory/Flash erase/write, Reboot, Flash identification, etc.
      mon: 0x0A,  # Monitoring Messages: Communication Status, CPU Load, Stack Usage, Task Status
      aid: 0x0B,  # AssistNow Aiding Messages: Ephemeris, Almanac, other A-GPS data input
      tim: 0x0D,  # Timing Messages: Time Pulse Output, Time Mark Results
      esf: 0x10,  # External Sensor Fusion Messages: External Sensor Measurements and Status Information
      mga: 0x13,  # Multiple GNSS Assistance Messages: Assistance data for various GNSS
      log: 0x21,  # Logging Messages: Log creation, deletion, info and retrieval
      sec: 0x27,  # Security Feature Messages
      hnr: 0x28   # High Rate Navigation Results Messages: High rate time, position, speed, heading
    }
  end

  def classes(attribute) when is_atom(attribute) do
    classes()[attribute]
  end

  def classes(attribute) when is_binary(attribute) do
    classes(String.to_atom(attribute))
  end

  def ack() do
    %{
      ack: 0x01,
      nack: 0x00
    }
  end

  def ack(attribute) when is_atom(attribute) do
    ack()[attribute]
  end

  def ack(attribute) when is_binary(attribute) do
    ack(String.to_atom(attribute))
  end

  def cfg() do
    %{
      ant: 0x13,
      batch: 0x93,
      cfg: 0x09,
      dat: 0x06,
      dgnss: 0x70,
      dynseed: 0x85,
      esrc: 0x60,
      fixseed: 0x84,
      geofence: 0x69,
      gnss: 0x3E,
      hnr: 0x5C,
      inf: 0x02,
      itfm: 0x39,
      logfilter: 0x47,
      msg: 0x01,
      nav5: 0x24,
      navx5: 0x23,
      nmea: 0x17,
      odo: 0x1E,
      pm2: 0x3B,
      pms: 0x86,
      prt: 0x00,
      pwr: 0x57,
      rate: 0x08,
      rinv: 0x34,
      rst: 0x04,
      rxm: 0x11,
      sbas: 0x16,
      slas: 0x8D,
      smgr: 0x62,
      tmode2: 0x3D,
      tmode3: 0x71,
      tp5: 0x31,
      txslot: 0x53,
      usb: 0x1B
    }
  end

  def cfg(attribute) when is_atom(attribute) do
    cfg()[attribute]
  end

  def cfg(attribute) when is_binary(attribute) do
    cfg(String.to_atom(attribute))
  end

  def mon() do
    %{
      batch: 0x32,
      gnss: 0x28,
      hw2: 0x0B,
      hw: 0x09,
      io: 0x02,
      msgpp: 0x06,
      patch: 0x27,
      rxbuf: 0x07,
      rxr: 0x21,
      smgr: 0x2E,
      txbuf: 0x08,
      ver: 0x04
    }
  end

  def mon(attribute) when is_atom(attribute) do
    mon()[attribute]
  end

  def mon(attribute) when is_binary(attribute) do
    mon(String.to_atom(attribute))
  end

  def nav() do
    %{
      aopstatus: 0x60,
      att: 0x05,
      clock: 0x22,
      dgps: 0x31,
      dop: 0x04,
      eoe: 0x61,
      geofence: 0x39,
      hpposecef: 0x13,
      hpposllh: 0x14,
      odo: 0x09,
      orb: 0x34,
      posecef: 0x01,
      posllh: 0x02,
      pvt: 0x07,
      relposned: 0x3C,
      resetodo: 0x10,
      sat: 0x35,
      sbas: 0x32,
      slas: 0x42,
      sol: 0x06,
      status: 0x03,
      svinfo: 0x30,
      svin: 0x3B,
      timebds: 0x24,
      timegal: 0x25,
      timeglo: 0x23,
      timegps: 0x20,
      timels: 0x26,
      timeutc: 0x21,
      velecef: 0x11,
      velned: 0x12
    }
  end

  def nav(attribute) when is_atom(attribute) do
    nav()[attribute]
  end

  def nav(attribute) when is_binary(attribute) do
    nav(String.to_atom(attribute))
  end
end
