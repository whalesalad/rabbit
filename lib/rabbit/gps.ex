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

  def debug(data, key) do
    debug([key, data])
    data
  end

  def send_packet(packet) do
    write(packet) |> debug('send_packet write response')

    get_all_bytes_available
  end

  def get_all_bytes_available do
    case get_all_bytes_available(get_ref()) do
      {:ok, raw_bytes} ->
        raw_bytes
          |> Binary.trim_trailing(0xFF)
          |> debug('raw_bytes')
      {:error, error} ->
        debug(['error', error])
        []
    end
  end

  def handle_byte_stream(<<data::binary>>) do
    Binary.split(data, <<0xB5, 0x62>>, global: true)
      |> debug('handle_byte_stream binary')
  end

  def handle_byte_stream(_) do
    []
  end

  def reject_blank(coll) do
    Enum.reject(coll, fn el -> el == "" end)
  end

  def get_all_packets_available do
    get_all_bytes_available
      |> debug('start get_all_bytes_available')
      |> handle_byte_stream()
      |> debug('handle byte stream')
      |> reject_blank()
      |> debug('reject blank')
      |> Enum.map(fn binary ->
        case Packet.decode(<<0xB5, 0x62>> <> binary) do
          { :ok, packet } ->
            { :ok, Packet.debug(packet) }
          { :error, message } ->
            IO.inspect({ :error, message })
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> debug('end get_all_packets_available')
  end

  def get_all_bytes_available(ref) do
    result = write_read(ref, <<0xFD>>, 2)

    case result do
      { :ok, <<bytes_to_read::16>> } ->
        read(bytes_to_read)

      { :error, message } ->
        { :error, message }

    end
  end

  def read_forever do
    get_all_packets_available
    :timer.sleep(200)
    read_forever
  end

  def get_version do
    get_version(get_ref)
  end

  def get_version(ref) do
    # stop_nav_pvt()

    # :timer.sleep(5)

    raw_response =
      Packet.p(:mon, :ver, [])
      |> Packet.encode()
      |> send_packet()

    # :timer.sleep(5)
    # start_nav_pvt()

    { :ok, response } = Packet.decode(raw_response, true)

    <<sw_version::binary-size(30), hw_version::binary-size(10), raw_extension::binary>> = response.payload

    extension = raw_extension
      |> String.split(<<0>>, trim: true)

    debug(%{
      sw_version: sw_version |> Binary.trim_trailing(0),
      hw_version: hw_version |> Binary.trim_trailing(0),
      extension: extension
    })
  end

  def get_port_configuration() do
    { :ok, raw_response } = Packet.encode(Packet.p(:cfg, :prt, [0])) |> send_packet

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

  def build_commands() do
    [
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

      # NAV-PVT OFF
      Packet.p(:cfg, :msg, [0x01,0x07,0x00]),

      # Rate 10Hz
      Packet.p(:cfg, :rate, [0x64,0x00,0x01,0x00,0x01,0x00])

      # NAV-POSLLH ON
      # Packet.p(:cfg, :msg, [0x01,0x02,0x00,0x01,0x00,0x00,0x00,0x00]),

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
    ]
  end

  def get_configuration() do
    get_ref |> write_read(Packet.encode)
  end

  def configure() do
    configure(build_commands)
  end

  def configure(commands) do
    get_ref |> configure(commands)
  end

  def configure(ref, commands) do
    commands |> Enum.each(fn packet ->
      # I2C.write(ref, @i2c_addr, Packet.encode(packet))
      write(Packet.encode(packet))

      # Simulating a 38400baud pace (or less),
      # otherwise commands are not accepted by the device.
      :timer.sleep(5)
    end)
  end

  def start_nav_pvt() do
    configure([Packet.p(:cfg, :msg, [0x01,0x07,0x01])])
  end

  def stop_nav_pvt() do
    configure([Packet.p(:cfg, :msg, [0x01,0x07,0x00])])
  end

  # def foo() do
  #   get_ref
  #     |> get_pvt
  #     |> IO.inspect
  # end
end
