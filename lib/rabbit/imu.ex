# defmodule IMU do
#   @port 0x69

#   @ub0_who_am_i 0x00

#   # Common to all user banks
#   @reg_bank_sel 0x7F

#   @reg_bank_sel_user_bank_0 0x00
#   @reg_bank_sel_user_bank_1 0x10
#   @reg_bank_sel_user_bank_2 0x20
#   @reg_bank_sel_user_bank_3 0x30

#   @ub0_pwr_mgmnt_1 0x06
#   @ub0_pwr_mgmnt_1_clock_sel_auto 0x01
#   @ub0_pwr_mgmnt_1_dev_reset 0x80

#   # User bank 0
#   @ub0_user_ctrl 0x03
#   @ub0_user_ctrl_i2c_mst_en 0x20

#   @ub0_pwr_mgmnt_2 0x07
#   @ub0_pwr_mgmnt_2_sen_enable 0x00

#   @ub2_accel_config 0x14

#   @ub3_i2c_mst_ctrl 0x01
#   @ub3_i2c_mst_ctrl_clk_400khz 0x07 # Gives 345.6kHz and is recommended to achieve max 400kHz



#   def write_register(ref, register, value) do
#     IO.puts("")
#     I2C.write(ref, @port, <<register, value>>) |> IO.inspect
#   end

#   def read_register(ref, register, bytes_to_read) do
#     I2C.write_read(ref, @port, <<register>>, bytes_to_read) |> IO.inspect
#   end

#   def change_user_bank(ref, bank) do
#     # I2C.write(ref, @port, <<@reg_bank_sel, bank>>) |> IO.inspect
#     write_register(ref, @reg_bank_sel, bank)
#   end

#   def reset(ref) do
#     change_user_bank(ref, @reg_bank_sel_user_bank_0)
#     write_register(ref, @ub0_pwr_mgmnt_1, @ub0_pwr_mgmnt_1_dev_reset)
#   end

#   def select_auto_clock_source(ref) do
#     change_user_bank(ref, @reg_bank_sel_user_bank_0)
#     write_register(ref, @ub0_pwr_mgmnt_1, @ub0_pwr_mgmnt_1_clock_sel_auto)
#   end

#   def who_am_i(ref) do
#     change_user_bank(ref, @reg_bank_sel_user_bank_0)
#     read_register(ref, @ub0_who_am_i, 1)
#   end

#   def enable_accelerometer_gyro(ref) do
#     change_user_bank(ref, @reg_bank_sel_user_bank_0)
#     write_register(ref, @ub0_pwr_mgmnt_2, <<0,0,0,0,0,0,0,0>>)
#   end

#   def begin(ref) do
#     change_user_bank(ref, @reg_bank_sel_user_bank_0)
#     select_auto_clock_source(ref)
#     enable_i2c_master(ref)
#     reset(ref)
#     select_auto_clock_source(ref)
#     who_am_i(ref)
#     enable_accelerometer_gyro(ref)
#     config_accelerometer(ref)
#   end

#   def config_accelerometer(ref) do
#     change_user_bank(ref, @reg_bank_sel_user_bank_2)

#     # UB2_ACCEL_CONFIG_FS_SEL_8G      0x04
#     # UB2_ACCEL_CONFIG_DLPFCFG_246HZ  0x01

#     write_register(ref, @ub2_accel_config, 0x04 ||| 0x01)
#   end

#   def config_gyroscope(ref) do
#     # GYRO_RANGE_2000DPS
#     # GYRO_DLPF_BANDWIDTH_197HZ
#   end

#   # def power_down_mag do
#   #   write_mag_register(ref, a b)
#   # end

#   def read_sensor(ref) do
#     # const uint8_t UB0_ACCEL_XOUT_H = 0x2D;
#     change_user_bank(ref, @reg_bank_sel_user_bank_0)
#     read_register(ref, 45, 14)
#   end

#   def enable_i2c_master(ref) do
#     change_user_bank(ref, @reg_bank_sel_user_bank_0)

#     write_register(ref, @ub0_user_ctrl, @ub0_user_ctrl_i2c_mst_en)

#     change_user_bank(ref, @reg_bank_sel_user_bank_3)

#     write_register(ref, @ub3_i2c_mst_ctrl, @ub3_i2c_mst_ctrl_clk_400khz)
#   end


# end
