defmodule Rabbit.Nmea do
  @doc ~S"""
  Parses the given `line` GPS coordinates.

  $GNVTG - Course and speed relative to the ground.
  $GNGGA - Time, position, and fix related data of the receiver.
  $GNGSA - Used to represent the ID’s of satellites which are used for position fix. When both GPS and GLONASS satellites are used in position solution, a $GNGSA sentence is used for GPS satellites and another $GNGSA sentence is used for GLONASS satellites. When only GPS satellites are used for position fix, a single $GPGSA sentence is output. When only GLONASS satellites are used, a single $GLGSA sentence is output.

  $GPGSV - GPS Satellites in view
  $GLGSV - Satellite information about elevation, azimuth and CNR, $GPGSV is used for GPS satellites, while $GLGSV is used for GLONASS satellites

  $GNGLL - Position, time and fix status.
  $GNRMC - Time, date, position, course and speed data.


  $GPBOD - Bearing, origin to destination
  $GPBWC - Bearing and distance to waypoint, great circle
  $GPGGA - Global Positioning System Fix Data
  $GPGLL - Geographic position, latitude / longitude
  $GPGSA - GPS DOP and active satellites
  $GPGSV - GPS Satellites in view
  $GPHDT - Heading, True
  $GPR00 - List of waypoints in currently active route
  $GPRMA - Recommended minimum specific Loran-C data
  $GPRMB - Recommended minimum navigation info
  $GPRMC - Recommended minimum specific GPS/Transit data
  $GPRTE - Routes
  $GPTRF - Transit Fix Data
  $GPSTN - Multiple Data ID
  $GPVBW - Dual Ground / Water Speed
  $GPVTG - Track made good and ground speed
  $GPWPL - Waypoint location
  $GPXTE - Cross-track error, Measured
  $GPZDA - Date & Time

  ## Examples

      iex> Rabbit.Nmea.parse("$GPGGA,064036.289,4836.53750,N,00740.93730,E,1,04,3.2,200.2,M,,,,0000*0E")
      {:ok, %{time: "064036.289", latitude: 48.60896, longitude: 7.68229}}

      iex> Rabbit.Nmea.parse("$GPGGA,064036.289,,,,,,,,,,,,,0000*0E")
      {:error, %{message: "empty data", data: "$GPGGA,064036.289,,,,,,,,,,,,,0000*0E"}}

      iex> Rabbit.Nmea.parse("$GPRMC,053740.000,A,2503.63190,N,12136.00990,E,2.69,79.65,100106,,,A*53 ")
      {:ok, %{time: "053740.000", latitude: 25.06053, longitude: 121.60017}}

      iex> Rabbit.Nmea.parse("$GPRMC,053740.000,A,4740.57735,N,0311.51847,W,2.69,79.65,100106,,,A*53 ")
      {:ok, %{time: "053740.000", latitude: 47.67629, longitude: -3.19197}}

      iex> Rabbit.Nmea.parse("$GPRMC,053740.000,A,2503.63190,N,12136.00999,E,2.69,79.65,100106,,,A*53 ")
      {:ok, %{time: "053740.000", latitude: 25.06053, longitude: 121.60017}}

      iex> Rabbit.Nmea.parse("$GPRMC,053740.000,V,,,,,,,,,,A*53")
      {:error, %{message: "empty data", data: "$GPRMC,053740.000,V,,,,,,,,,,A*53"}}

      iex> Rabbit.Nmea.parse("bad data")
      {:error, %{message: "can't parse data", data: "bad data"}}
  """

  def parse(data) do
    data
    |> String.split(",")
    |> to_gps_struct()
  end

  defp to_gps_struct(
         [
           "$GPGGA",
           time,
           latitude,
           latitude_cardinal,
           longitude,
           longitude_cardinal,
           _type,
           _nb_satellites,
           _precision,
           _altitude,
           _altitude_unit,
           _,
           _,
           _,
           _sig
         ] = data
       ) do
    with {:ok, latitude} <- to_degrees("#{latitude},#{latitude_cardinal}"),
         {:ok, longitude} <- to_degrees("#{longitude},#{longitude_cardinal}") do
      {:ok,
       %{
         time: time,
         latitude: latitude,
         longitude: longitude
       }}
    else
      {:error, %{message: "empty data"}} ->
        {:error, %{message: "empty data", data: Enum.join(data, ",")}}

      _ ->
        {:error, %{message: "can't parse data", data: Enum.join(data, ",")}}
    end
  end

  defp to_gps_struct(
         [
           "$GNRMC",
           time,
           _position_status,
           latitude,
           latitude_cardinal,
           longitude,
           longitude_cardinal,
           _speed,
           _track,
           _date,
           _mode_indicator,
           _foo,
           _sig
         ] = data
       ) do

    IO.puts(IO.inspect(data))

    with {:ok, latitude} <- to_degrees("#{latitude},#{latitude_cardinal}"),
         {:ok, longitude} <- to_degrees("#{longitude},#{longitude_cardinal}") do
      {:ok,
       %{
         time: time,
         latitude: latitude,
         longitude: longitude
       }}
    else
      {:error, %{message: "empty data"}} ->
        {:error, %{message: "empty data", data: Enum.join(data, ",")}}

      _ ->
        {:error, %{message: "can't parse data", data: Enum.join(data, ",")}}
    end
  end

  defp to_gps_struct(
         [
           "$GPRMC",
           time,
           _data_state,
           latitude,
           latitude_cardinal,
           longitude,
           longitude_cardinal,
           _speed,
           _,
           _,
           _,
           _,
           _sig
         ] = data
       ) do
    with {:ok, latitude} <- to_degrees("#{latitude},#{latitude_cardinal}"),
         {:ok, longitude} <- to_degrees("#{longitude},#{longitude_cardinal}") do
      {:ok,
       %{
         time: time,
         latitude: latitude,
         longitude: longitude
       }}
    else
      {:error, %{message: "empty data"}} ->
        {:error, %{message: "empty data", data: Enum.join(data, ",")}}

      _ ->
        {:error, %{message: "can't parse data", data: Enum.join(data, ",")}}
    end
  end

  defp to_gps_struct(data) do
    {:error, %{message: "can't parse data", data: Enum.join(data, ",")}}
  end

  @doc ~S"""
  Convert NMEA coordinates to DDS coordinates.

  ## Examples
      iex> Rabbit.Nmea.to_degrees("4902.63177,N")
      {:ok, 49.04386}

      iex> Rabbit.Nmea.to_degrees("00200.69856,E")
      {:ok, 2.01164}

      iex> Rabbit.Nmea.to_degrees("12136.69856,E")
      {:ok, 121.61164}

      iex> Rabbit.Nmea.to_degrees("4740.58920,N")
      {:ok, 47.67649}

      iex> Rabbit.Nmea.to_degrees("00200.69869,E")
      {:ok, 2.01164}

      iex> Rabbit.Nmea.to_degrees("4902.63175,S")
      {:ok, -49.04386}

      iex> Rabbit.Nmea.to_degrees("00200.69856,W")
      {:ok, -2.01164}
  """
  def to_degrees(
        <<degrees::bytes-size(2)>> <>
          <<minutes::bytes-size(8)>> <>
          <<_sep::bytes-size(1)>> <>
          <<cardinal::bytes-size(1)>>
      ) do
    {:ok, do_to_degrees(degrees, minutes, cardinal)}
  end

  def to_degrees(
        <<degrees::bytes-size(3)>> <>
          <<minutes::bytes-size(7)>> <>
          <<_sep::bytes-size(1)>> <>
          <<cardinal::bytes-size(1)>>
      ) do
    {:ok, do_to_degrees(degrees, minutes, cardinal)}
  end

  def to_degrees(
        <<degrees::bytes-size(3)>> <>
          <<minutes::bytes-size(8)>> <>
          <<_sep::bytes-size(1)>> <>
          <<cardinal::bytes-size(1)>>
      ) do
    {:ok, do_to_degrees(degrees, minutes, cardinal)}
  end

  def to_degrees(",") do
    {:error, %{message: "empty data"}}
  end

  defp do_to_degrees(degrees, minutes, cardinal) do
    degrees = degrees |> float_parse()
    minutes = minutes |> float_parse()
    (degrees + minutes / 60) |> Float.round(5) |> with_cardinal_orientation(cardinal)
  end

  defp with_cardinal_orientation(degrees, cardinal) when cardinal in ["N", "E"] do
    degrees
  end

  defp with_cardinal_orientation(degrees, cardinal) when cardinal in ["S", "W"] do
    -degrees
  end

  defp float_parse(value) do
    {value_parsed, _} = Float.parse(value)
    value_parsed
  end
end
