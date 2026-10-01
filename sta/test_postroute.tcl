# G02 - Post-route Fmax sweep
# Corner: max_ss_100C_1v60

set liberty "/root/.volare/volare/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib"

set odb_file "/workspace/openlane/runs/test_config/52-odb-cellfrequencytables/moving_average_8.odb"

set spef_file "/workspace/openlane/runs/test_config/53-openroad-rcx/max/moving_average_8.max.spef"

set periods {10.0 9.0 8.0 7.0 6.5 6.0}

foreach period $periods {

    puts ""
    puts "========================================"
    puts "Clock period = $period ns"
    puts "========================================"

    # Load design
    read_liberty $liberty
    read_db $odb_file
    read_spef $spef_file

    # Create clock for this period
    create_clock -name clk -period $period [get_ports clk]
    set_clock_transition 0.1500 [get_clocks clk]
    set_clock_uncertainty 0.2500 [get_clocks clk]
    set_propagated_clock [get_clocks clk]

    # Match main timing constraints
    set_input_delay 2.0000 -clock clk [get_ports {rst_n}]
    set_input_delay 2.0000 -clock clk [get_ports {ui_in[*]}]
    set_input_delay 2.0000 -clock clk [get_ports {uio_in[*]}]

    set_output_delay 2.0000 -clock clk [get_ports {uo_out[*]}]
    set_output_delay 2.0000 -clock clk [get_ports {uio_out[*]}]

    set_load -pin_load 0.0334 [all_outputs]

    set_max_transition 0.7500 [current_design]
    set_max_capacitance 0.2000 [current_design]
    set_max_fanout 10.0 [current_design]

    report_checks -path_delay max -group_count 1
}