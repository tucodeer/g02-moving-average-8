read_liberty /home/user/.volare/volare/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog /workspace/synth/netlist/moving_average_8_sky130.v

link_design moving_average_8

read_sdc /workspace/sta/constraints_fmax_sliding.sdc

report_checks -path_delay max -fields {slew cap input_pins} -digits 3
report_tns
report_wns
