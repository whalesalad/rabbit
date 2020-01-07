defmodule Rabbit.GPS do
  alias Rabbit.Ublox.Packet
  alias Circuits.I2C

  @i2c_addr 0x42

  def foo() do
    {:ok, ref} = I2C.open("i2c-1")
  end
end
