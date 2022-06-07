set_property PACKAGE_PIN R3 [get_ports SYS_CLK_P]
set_property PACKAGE_PIN P3 [get_ports SYS_CLK_N]
set_property PACKAGE_PIN R6 [get_ports {GPIO_DIP_SW[3]}]
set_property PACKAGE_PIN R7 [get_ports {GPIO_DIP_SW[2]}]
set_property PACKAGE_PIN P8 [get_ports {GPIO_DIP_SW[1]}]
set_property PACKAGE_PIN R8 [get_ports {GPIO_DIP_SW[0]}]
set_property PACKAGE_PIN U22 [get_ports PHY_TX_CLK]
set_property PACKAGE_PIN T15 [get_ports PHY_TX_CTRL]
set_property PACKAGE_PIN U16 [get_ports {PHY_TXD[0]}]
set_property PACKAGE_PIN U15 [get_ports {PHY_TXD[1]}]
set_property PACKAGE_PIN T18 [get_ports {PHY_TXD[2]}]
set_property PACKAGE_PIN T17 [get_ports {PHY_TXD[3]}]
set_property PACKAGE_PIN U21 [get_ports PHY_RX_CLK]
set_property PACKAGE_PIN U14 [get_ports PHY_RX_CTRL]
set_property PACKAGE_PIN U17 [get_ports {PHY_RXD[0]}]
set_property PACKAGE_PIN V17 [get_ports {PHY_RXD[1]}]
set_property PACKAGE_PIN V16 [get_ports {PHY_RXD[2]}]
set_property PACKAGE_PIN V14 [get_ports {PHY_RXD[3]}]
set_property PACKAGE_PIN V18 [get_ports PHY_RSTn]
set_property PACKAGE_PIN N18 [get_ports SCL_OUT]
set_property PACKAGE_PIN K25 [get_ports SDA_IO]


set_property IOSTANDARD SSTL15 [get_ports {GPIO_DIP_SW[3]}]
set_property IOSTANDARD SSTL15 [get_ports {GPIO_DIP_SW[2]}]
set_property IOSTANDARD SSTL15 [get_ports {GPIO_DIP_SW[1]}]
set_property IOSTANDARD SSTL15 [get_ports {GPIO_DIP_SW[0]}]
set_property IOSTANDARD LVDS_25  [get_ports SYS_CLK_P]
set_property IOSTANDARD LVDS_25  [get_ports SYS_CLK_N]
set_property IOSTANDARD LVCMOS18 [get_ports PHY_TX_CLK]
set_property IOSTANDARD LVCMOS18 [get_ports PHY_TX_CTRL]
set_property IOSTANDARD LVCMOS18 [get_ports {PHY_TXD[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {PHY_TXD[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {PHY_TXD[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {PHY_TXD[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports PHY_RX_CLK]
set_property IOSTANDARD LVCMOS18 [get_ports PHY_RX_CTRL]
set_property IOSTANDARD LVCMOS18 [get_ports {PHY_RXD[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {PHY_RXD[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {PHY_RXD[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {PHY_RXD[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports PHY_RSTn]
set_property IOSTANDARD LVCMOS18 [get_ports SCL_OUT]
set_property IOSTANDARD LVCMOS18 [get_ports SDA_IO]

create_clock -period 8.000 -name PHY_RX_CLK -waveform {0.000 4.000} [get_ports PHY_RX_CLK]
create_clock -period 5.000 -name SYS_CLK_P -waveform {0.000 2.500} [get_ports SYS_CLK_P]

set_false_path -from [get_pins GMII_1000M_reg/C]

set_input_delay -clock [get_clocks PHY_RX_CLK] -max 3.000 [get_ports {PHY_RX_CTRL {PHY_RXD[*]}}]
set_input_delay -clock [get_clocks PHY_RX_CLK] -min 1.000 [get_ports {PHY_RX_CTRL {PHY_RXD[*]}}]

set_max_delay -datapath_only -from [get_clocks CLK_125M_PLL] -to [get_ports {PHY_TXD[*]}] 4
set_max_delay -datapath_only -from [get_clocks CLK_125M_PLL] -to [get_ports PHY_TX_CTRL] 4
set_max_delay -datapath_only -from [get_clocks CLK_125M_PLL_DELAY] -to [get_ports PHY_TX_CLK] 4


set_max_delay -datapath_only -from [get_clocks CLK_200M_PLL] -to [get_port PHY_RSTn] 10
set_min_delay                -from [get_clocks CLK_200M_PLL] -to [get_port PHY_RSTn] 0
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 12 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]



