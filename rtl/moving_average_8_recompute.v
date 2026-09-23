module moving_average_8_recompute (
    input        clk,
    input        rst_n,
    input  [7:0]  ui_in,
    input  [7:0]  uio_in,
    output [7:0]  uo_out,
    output [7:0]  uio_out
);

    reg [7:0] sample_mem [0:7];
    reg [2:0] wr_ptr;
    reg [3:0] sample_count;

    reg [7:0] out_data;
    reg       out_valid;

    wire [10:0] window_sum;

    /*
     * Recompute the sum of the current 8-sample window.
     * The sample at wr_ptr is the oldest sample and is
     * replaced by ui_in, so subtract it and add ui_in.
     */
    assign window_sum =
          {3'b000, sample_mem[0]}
        + {3'b000, sample_mem[1]}
        + {3'b000, sample_mem[2]}
        + {3'b000, sample_mem[3]}
        + {3'b000, sample_mem[4]}
        + {3'b000, sample_mem[5]}
        + {3'b000, sample_mem[6]}
        + {3'b000, sample_mem[7]}
        - {3'b000, sample_mem[wr_ptr]}
        + {3'b000, ui_in};

    assign uo_out       = out_data;
    assign uio_out[0]   = out_valid;
    assign uio_out[7:1] = 7'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_mem[0] <= 8'd0;
            sample_mem[1] <= 8'd0;
            sample_mem[2] <= 8'd0;
            sample_mem[3] <= 8'd0;
            sample_mem[4] <= 8'd0;
            sample_mem[5] <= 8'd0;
            sample_mem[6] <= 8'd0;
            sample_mem[7] <= 8'd0;

            wr_ptr       <= 3'd0;
            sample_count <= 4'd0;
            out_data     <= 8'd0;
            out_valid    <= 1'b0;
        end
        else if (uio_in[0]) begin

            sample_mem[wr_ptr] <= ui_in;

            if (sample_count < 4'd8)
                sample_count <= sample_count + 1'b1;

            if (wr_ptr == 3'd7)
                wr_ptr <= 3'd0;
            else
                wr_ptr <= wr_ptr + 1'b1;

            if (sample_count >= 4'd7) begin
                out_data  <= window_sum >> 3;
                out_valid <= 1'b1;
            end

        end
    end

endmodule
