`timescale 1ns/1ps

module moving_average_8_tb;

    reg        clk;
    reg        rst_n;
    reg [7:0]  ui_in;
    reg [7:0]  uio_in;

    wire [7:0] uo_out;
    wire [7:0] uio_out;


    // =========================================
    // Reference model
    // =========================================

    reg [7:0] ref_mem [0:7];

    integer ref_ptr;
    integer ref_count;
    integer ref_sum;
    integer i;


    // =========================================
    // DUT
    // =========================================

    moving_average_8 dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .ui_in  (ui_in),
        .uio_in (uio_in),
        .uo_out (uo_out),
        .uio_out(uio_out)
    );


    // =========================================
    // Clock
    // =========================================

    // Clock period = 10 ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

        // =========================================
    // Send sample and check DUT
    // =========================================

    task send_and_check;
        input [7:0] data;

        reg [7:0] expected;

        begin
            // Đưa sample vào ở cạnh xuống
            @(negedge clk);

            ui_in = data;
            uio_in[0] = 1'b1;

            // Cập nhật reference model
            if (ref_count < 8) begin

                ref_mem[ref_ptr] = data;
                ref_sum = ref_sum + data;
                ref_count = ref_count + 1;

            end
            else begin

                ref_sum = ref_sum - ref_mem[ref_ptr] + data;
                ref_mem[ref_ptr] = data;

            end

            // Circular pointer của reference
            if (ref_ptr == 7)
                ref_ptr = 0;
            else
                ref_ptr = ref_ptr + 1;

            // Expected output
            expected = ref_sum >> 3;

            // Chờ DUT xử lý sample
            @(posedge clk);
            #1;

            // ---------------------------------
            // Chưa đủ 8 sample
            // ---------------------------------

            if (ref_count < 8) begin

                if (uio_out[0] !== 1'b0) begin

                    $display(
                        "ERROR: sample=%0d | count=%0d | valid should be 0, got %b",
                        data,
                        ref_count,
                        uio_out[0]
                    );

                end
                else begin

                    $display(
                        "PASS: sample=%0d | count=%0d | output invalid",
                        data,
                        ref_count
                    );

                end

            end

            // ---------------------------------
            // Đã đủ 8 sample
            // ---------------------------------

            else begin

                if (uio_out[0] !== 1'b1) begin

                    $display(
                        "ERROR: sample=%0d | valid should be 1",
                        data
                    );

                end
                else if (uo_out !== expected) begin

                    $display(
                        "ERROR: sample=%0d | expected=%0d | got=%0d",
                        data,
                        expected,
                        uo_out
                    );

                end
                else begin

                    $display(
                        "PASS: sample=%0d | expected=%0d | got=%0d",
                        data,
                        expected,
                        uo_out
                    );

                end

            end

        end
    endtask
    // =========================================
    // Reset DUT and reference model
    // =========================================

    task reset_test;

        begin

            rst_n  = 1'b0;
            ui_in  = 8'd0;
            uio_in = 8'd0;

            ref_ptr   = 0;
            ref_count = 0;
            ref_sum   = 0;

            for (i = 0; i < 8; i = i + 1)
                ref_mem[i] = 8'd0;

            #12;

            rst_n = 1'b1;

        end

    endtask

    // =========================================
    // Test sequence
    // =========================================

        initial begin

        // =====================================
        // Test 1
        // Basic window filling
        // =====================================

        reset_test;

        send_and_check(8'd10);
        send_and_check(8'd20);
        send_and_check(8'd30);
        send_and_check(8'd40);
        send_and_check(8'd50);
        send_and_check(8'd60);
        send_and_check(8'd70);
        send_and_check(8'd80);


        // =====================================
        // Test 2
        // Sliding accumulation
        // =====================================

        reset_test;

        send_and_check(8'd10);
        send_and_check(8'd20);
        send_and_check(8'd30);
        send_and_check(8'd40);
        send_and_check(8'd50);
        send_and_check(8'd60);
        send_and_check(8'd70);
        send_and_check(8'd80);

        send_and_check(8'd100);


        // =====================================
        // Test 3
        // Constant sequence
        // =====================================

        reset_test;

        send_and_check(8'd50);
        send_and_check(8'd50);
        send_and_check(8'd50);
        send_and_check(8'd50);
        send_and_check(8'd50);
        send_and_check(8'd50);
        send_and_check(8'd50);
        send_and_check(8'd50);
        send_and_check(8'd50);
        send_and_check(8'd50);
        // =====================================
        // Test 4
        // Step sequence
        // =====================================

        reset_test;

        // Initial value = 0
        send_and_check(8'd0);
        send_and_check(8'd0);
        send_and_check(8'd0);
        send_and_check(8'd0);
        send_and_check(8'd0);
        send_and_check(8'd0);
        send_and_check(8'd0);
        send_and_check(8'd0);

        // Step from 0 to 80
        send_and_check(8'd80);
        send_and_check(8'd80);
        send_and_check(8'd80);
        send_and_check(8'd80);
        send_and_check(8'd80);
        send_and_check(8'd80);
        send_and_check(8'd80);
        send_and_check(8'd80);

        // Test 5: Random sequence
        reset_test;

        repeat (30) begin
            send_and_check($random % 256);
        end

        // Test 6: Accumulator overflow test
        reset_test;

        send_and_check(8'd255);
        send_and_check(8'd255);
        send_and_check(8'd255);
        send_and_check(8'd255);
        send_and_check(8'd255);
        send_and_check(8'd255);
        send_and_check(8'd255);
        send_and_check(8'd255);

        // Continue sliding with maximum value
        send_and_check(8'd255);
        send_and_check(8'd255);
        send_and_check(8'd255);
        // =====================================
        // Finish
        // =====================================

        #10;

        $display("--------------------------------");
        $display("Simulation finished.");
        $display("--------------------------------");

        $finish;

    end

endmodule