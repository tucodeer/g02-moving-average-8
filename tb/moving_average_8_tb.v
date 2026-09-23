`timescale 1ns/1ps

module moving_average_8_tb;

    reg        clk;
    reg        rst_n;
    reg [7:0]  ui_in;
    reg [7:0]  uio_in;

    wire [7:0] uo_out;
    wire [7:0] uio_out;

    moving_average_8 dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .ui_in   (ui_in),
        .uio_in  (uio_in),
        .uo_out  (uo_out),
        .uio_out (uio_out)
    );

    // Clock
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        clk    = 1'b0;
        rst_n  = 1'b0;
        ui_in  = 8'd0;
        uio_in = 8'd0;

        #12;
        rst_n = 1'b1;

        // Sample 1
        #3;  ui_in = 8'd10;  uio_in = 8'b0000_0001;

        // Sample 2
        #10; ui_in = 8'd20;

        // Sample 3
        #10; ui_in = 8'd30;

        // Sample 4
        #10; ui_in = 8'd40;

        // Sample 5
        #10; ui_in = 8'd50;

        // Sample 6
        #10; ui_in = 8'd60;

        // Sample 7
        #10; ui_in = 8'd70;

        // Sample 8
        #10; ui_in = 8'd80;

        // Sample 9
        #10; ui_in = 8'd100;

        #10;
        $finish;
    end

    // Monitor
    always @(posedge clk) begin
        $display(
            "time=%0t | input=%0d | count=%0d | ptr=%0d | sum=%0d | out=%0d | valid=%b",
            $time,
            ui_in,
            dut.sample_count,
            dut.wr_ptr,
            dut.sum,
            uo_out,
            uio_out[0]
        );
    end

endmodule