create_clock -name clk -period 10 [get_ports clk]

set_input_delay 0 -clock clk [get_ports ui_in]
set_input_delay 0 -clock clk [get_ports uio_in]
set_input_delay 0 -clock clk [get_ports rst_n]

set_output_delay 0 -clock clk [get_ports uo_out]
set_output_delay 0 -clock clk [get_ports uio_out]