defmodule Rabbit.GPS do
  alias Rabbit.Ublox.Packet
  alias Circuits.I2C

  @i2c_addr 0x42

  def get_port_configuration(ref) do
    {:ok, <<0xFF, response::binary>>} = I2C.write_read(
      ref,
      @i2c_addr,
      Packet.encode(Packet.p(:cfg, :prt, [0])),
      29
    )

    payload_size = 20 * 8

    <<0xB5, 0x62, _class, _id, _length::16-little, payload::bytes-size(20), _cka, _ckb>> = response

    <<
      port_id,
      _,
      tx_ready::bytes-size(2),
      mode::bytes-size(4),
      _::bytes-size(4),
      in_proto_mask::bytes-size(2),
      out_proto_mask::bytes-size(2),
      flags::bytes-size(2),
      _::bytes-size(2)
    >> = payload

    %{
      port_id: port_id,
      tx_ready: tx_ready,
      mode: mode,
      in_proto_mask: in_proto_mask,
      out_proto_mask: out_proto_mask,
      flags: flags
    }
  end

  def foo() do
    {:ok, ref} = I2C.open("i2c-1")

    ref
      |> get_port_configuration
      |> IO.inspect
  end
end
