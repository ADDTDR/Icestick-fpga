`timescale 1ns/1ps

module i2s_tx_tb;
    localparam integer SAMPLE_BITS = 16;
    localparam integer CHANNEL_BITS = 32;
    localparam integer BCLK_DIV = 2;
    localparam integer FRAME_BITS = 2 * CHANNEL_BITS;
    localparam signed [SAMPLE_BITS-1:0] SAMPLE_L = 16'hA55A;
    localparam signed [SAMPLE_BITS-1:0] SAMPLE_R = 16'h3CC3;

    reg clk = 1'b0;
    reg signed [SAMPLE_BITS-1:0] sample_l = SAMPLE_L;
    reg signed [SAMPLE_BITS-1:0] sample_r = SAMPLE_R;
    wire sample_req;
    wire bclk;
    wire lrclk;
    wire sdata;

    integer bit_index = 0;
    integer frame_index = 0;
    integer req_pulses = 0;

    i2s_tx #(
        .SAMPLE_BITS(SAMPLE_BITS),
        .CHANNEL_BITS(CHANNEL_BITS),
        .BCLK_DIV(BCLK_DIV)
    ) dut (
        .clk(clk),
        .sample_l(sample_l),
        .sample_r(sample_r),
        .sample_req(sample_req),
        .bclk(bclk),
        .lrclk(lrclk),
        .sdata(sdata)
    );

    always #5 clk = ~clk;

    function expected_lrclk;
        input integer index;
        begin
            if (index < CHANNEL_BITS - 1)
                expected_lrclk = 1'b0;
            else if (index < FRAME_BITS - 1)
                expected_lrclk = 1'b1;
            else
                expected_lrclk = 1'b0;
        end
    endfunction

    function expected_sdata;
        input integer index;
        input signed [SAMPLE_BITS-1:0] left_sample;
        input signed [SAMPLE_BITS-1:0] right_sample;
        begin
            if (index < SAMPLE_BITS)
                expected_sdata = left_sample[SAMPLE_BITS - 1 - index];
            else if (index >= CHANNEL_BITS && index < CHANNEL_BITS + SAMPLE_BITS)
                expected_sdata = right_sample[(CHANNEL_BITS + SAMPLE_BITS - 1) - index];
            else
                expected_sdata = 1'b0;
        end
    endfunction

    task automatic check_bit;
        input integer index;
        input integer frame_no;
        input signed [SAMPLE_BITS-1:0] left_sample;
        input signed [SAMPLE_BITS-1:0] right_sample;
        reg expected_ws;
        reg expected_sd;
        begin
            expected_ws = expected_lrclk(index);
            expected_sd = expected_sdata(index, left_sample, right_sample);

            if (lrclk !== expected_ws) begin
                $display("LRCLK mismatch at frame %0d bit %0d: got %b expected %b", frame_no, index, lrclk, expected_ws);
                $fatal(1);
            end

            if (sdata !== expected_sd) begin
                $display("SDATA mismatch at frame %0d bit %0d: got %b expected %b", frame_no, index, sdata, expected_sd);
                $fatal(1);
            end
        end
    endtask

    always @(posedge clk)
        if (sample_req)
            req_pulses <= req_pulses + 1;

    always @(posedge bclk) begin
        check_bit(bit_index, frame_index, SAMPLE_L, SAMPLE_R);

        if (bit_index == FRAME_BITS - 1) begin
            bit_index <= 0;
            frame_index <= frame_index + 1;
        end else begin
            bit_index <= bit_index + 1;
        end
    end

    initial begin
        repeat (FRAME_BITS * 4) @(posedge bclk);

        if (req_pulses < 3) begin
            $display("sample_req did not pulse once per frame as expected");
            $fatal(1);
        end

        $display("i2s_tx_tb PASS");
        $finish;
    end
endmodule