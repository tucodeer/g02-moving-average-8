module moving_average_8 (
    input   clk,
    input   rst_n,
    input   [7:0]   ui_in,
    input   [7:0]   uio_in,
    
    output  [7:0]   uo_out,
    output  [7:0]   uio_out
);
    //KHAI BÁO
    // Vong 8 mau

    reg [7:0] sample_mem [0:7];

    // Tro vao mau cu nhat/ ghi de len dia chi do

    reg [2:0] wr_ptr;

    // Chay tong 8 mau cua so trượt

    reg [10:0] sum;

    // Dau ra thanh ghi

    reg [7:0] out_data;
    reg       out_valid;

    reg [3:0] sample_count;

    assign uo_out    = out_data;
    assign uio_out[0]= out_valid;
    assign uio_out[7:1]=7'b0;

    //CHÂN RESET 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr       <= 3'd0;
            sample_count <= 4'd0;
            sum          <= 11'd0;
            out_data     <= 8'd0;
            out_valid    <= 1'b0;
            sample_mem[0] <= 8'd0;
            sample_mem[1] <= 8'd0;
            sample_mem[2] <= 8'd0;
            sample_mem[3] <= 8'd0;
            sample_mem[4] <= 8'd0;
            sample_mem[5] <= 8'd0;
            sample_mem[6] <= 8'd0;
            sample_mem[7] <= 8'd0;
        end

        // CIRCULAR BUFFER (VÒNG LẶP ĐỆM)
        else if (uio_in[0]) begin

            // Store new sample
            sample_mem[wr_ptr] <= ui_in;

            // Count valid samples
            if (sample_count < 4'd8)
                sample_count <= sample_count + 1'b1;

            // Move write pointer
            if (wr_ptr == 3'd7)
                wr_ptr <= 3'd0;
            else
                wr_ptr <= wr_ptr + 1'b1;

            // Output becomes valid after receiving 8 samples
            if (sample_count == 4'd7) //dang nhan sample thu 8 -> sau clk này là đủ 8 mẫu 
                out_valid <= 1'b1;

            if (sample_count < 4'd8) begin
                sum <= sum + ui_in;

                if (sample_count == 4'd7)
                    out_data <= (sum + ui_in) >> 3;
            end
            else begin
                sum <= (sum - sample_mem[wr_ptr]) + ui_in;
                out_data <= ((sum - sample_mem[wr_ptr]) + ui_in) >> 3;
            end
        end
        //

    end




endmodule