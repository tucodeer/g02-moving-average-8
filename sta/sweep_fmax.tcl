# G02 - Post-route Fmax sweep
# Corner: max_ss_100C_1v60

set odb_file "/workspace/openlane/runs/test_config/52-odb-cellfrequencytables/moving_average_8.odb"
set spef_file "/workspace/openlane/runs/test_config/53-openroad-rcx/max/moving_average_8.max.spef"

set liberty "/home/user/.volare/volare/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib"

read_liberty $liberty
read_db $odb_file
read_spef $spef_file

# Keep the same timing environment as OpenLane,
# but replace the clock period for each sweep point.
set periods {10.0 9.0 8.0 7.0 6.5 6.0}

foreach period $periods {
    puts ""
    puts "========================================"
    puts "Clock period = $period ns"
    puts "========================================"

    reset_design

    read_liberty $liberty
    read_db $odb_file
    read_spef $spef_file

    create_clock -name clk -period $period [get_ports clk]
    set_clock_transition 0.1500 [get_clocks clk]
    set_clock_uncertainty 0.2500 [get_clocks clk]
    set_propagated_clock [get_clocks clk]

    report_checks -path_delay max -group_count 1
}