defmodule Rabbit.GPS do
  alias Binary
  alias Rabbit.Ublox.Packet
  alias Circuits.I2C

  @i2c_addr 0x42

  # #########################################################
  #
  # TODO move all this i2c logic to an i2c/'hardware' layer
  # ideally something that will constantly read data and pass
  # it off somewhere else until it is issued a command?
  #
  # So we'll need a 'sink' to capture all the shit that ever
  # goes into or comes out of this device and then hopefully
  # we'll be able to play that data back, use it in tests, etc...
  #
  # Added benefit is that this sink can essnetially just write
  # itself to a log endpoint somewhere like cloudwatch.
  #
  def get_ref() do
    {:ok, ref} = I2C.open("i2c-1")
    ref
  end

  def read(ref, num_bytes) do
    IO.inspect(['read', num_bytes])
    I2C.read(ref, @i2c_addr, num_bytes)
  end

  def read(num_bytes) do
    read(get_ref(), num_bytes)
  end

  def write(ref, payload) do
    IO.inspect(['write', ref, payload])
    I2C.write(ref, @i2c_addr, payload)
  end

  def write(payload) do
    write(get_ref(), payload)
  end

  def write_read(ref, payload, num_bytes_to_read \\ 1) do
    IO.inspect(['write_read', ref, payload, num_bytes_to_read])
    I2C.write_read(ref, @i2c_addr, payload, num_bytes_to_read)
  end

  def write_read(payload) do
    write_read(get_ref(), payload, 1)
  end
  # #########################################################

  def debug(data) do
    data |>
      IO.inspect(limit: :infinity)
      # IO.inspect(limit: :infinity, binaries: :as_binaries)
  end

  def send_packet(packet) do
    write(packet) |> debug

    get_all_bytes_available
  end

  def get_all_bytes_available do
    get_all_bytes_available(get_ref())
  end

  def get_all_packets_available do
    get_all_bytes_available
      |> elem(1)
      |> debug
      |> Binary.split(<<0xB5, 0x62>>, global: true)
      |> Enum.reject(fn el -> el == "" end)
      |> Enum.map(fn binary ->
        decoded = Packet.decode(<<0xB5, 0x62>> <> binary)
        case decoded do
          { :ok, packet } ->
            { :ok, Packet.debug(packet) }
          { :error, message } ->
            { :error, message }
        end
      end)
      |> debug
  end

  def get_all_bytes_available(ref) do
    result = write_read(ref, <<0xFD>>, 2)

    # debug([:result, result])

    case result do
      { :ok, <<bytes_to_read::16>> } ->
        debug({:bytes_to_read, bytes_to_read})
        read(bytes_to_read)

      { :error, message } ->
        { :error, message }

    end
  end

  def get_version do
    get_version(get_ref)
  end

  def vp do
    Packet.encode(Packet.p(:mon, :ver, []))
  end

  def get_version(ref) do
    { :ok, raw_response } = Packet.encode(Packet.p(:mon, :ver, [])) |> send_packet

    debug(['response in get_version?', raw_response])

    { :ok, response } = Packet.decode(raw_response, true)

    response.payload
      |> String.split(<<0>>, trim: true)
      |> debug
  end

  def get_port_configuration() do
    { :ok, raw_response } = Packet.encode(Packet.p(:cfg, :prt, [])) |> send_packet

    debug(['response in get_port_configuration', raw_response])

    { :ok, response } = Packet.decode(raw_response, true)

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
    >> = response.payload

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
      # Packet.p(:cfg, :gnss, [
      #   0x00, # msgVer
      #   0xFF, # numTrkChHw
      #   0xFF, # numTrkChUse
      #   0x04, # numConfigBlocks below ->

      #   # gnssId, resTrkCh, maxTrkCh, reserved1,
      #   # flags::4 bytes: <<_, sigCfgMask, ..... enable::1>>
      #   #

      #   # GPS, on set L2C
      #   0x00, 0x10, 0xFF, 0x00,
      #   0x01, 0x10, 0x00, 0x01,

      #   # SBAS, on
      #   0x01, 0x10, 0xFF, 0x00,
      #   0x00, 0x01, 0x00, 0x01,

      #   # QZSS, off
      #   0x05, 0x00, 0x03, 0x00,
      #   0x00, 0x00, 0x00, 0x00,

      #   # GLONASS, off
      #   0x06, 0x08, 0xFF, 0x00,
      #   0x00, 0x00, 0x00, 0x00
      # ]),

      # NAV-POSLLH ON
      # Packet.p(:cfg, :msg, [0x01,0x02,0x00,0x01,0x00,0x00,0x00,0x00]),

      # Rate 10Hz
      Packet.p(:cfg, :rate, [0x64,0x00,0x01,0x00,0x01,0x00])
    ]

    commands |> Enum.each(fn packet ->
      # I2C.write(ref, @i2c_addr, Packet.encode(packet))
      write(Packet.encode(packet))

      # Simulating a 38400baud pace (or less),
      # otherwise commands are not accepted by the device.
      :timer.sleep(5)
    end)
  end

  # def foo() do
  #   get_ref
  #     |> get_pvt
  #     |> IO.inspect
  # end
end
