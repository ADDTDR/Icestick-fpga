module uart_receiver(
    input clk,
    input RxD,
    output reg RxD_data_ready = 0,
    output reg [7:0] RxD_data = 0,
    output RxD_idle,
    output reg RxD_endofpacket = 0
);

    parameter ClkFrequency = 12000000;
    parameter Baud = 115200;
    parameter Oversampling = 8;

    generate
        if(ClkFrequency<Baud*Oversampling) ASSERTION_ERROR PARAMETER_OUT_OF_RANGE("Frequency too low for current Baud rate and oversampling");
        if(Oversampling<8 || ((Oversampling & (Oversampling-1))!=0)) ASSERTION_ERROR PARAMETER_OUT_OF_RANGE("Invalid oversampling value");
    endgenerate

    reg [3:0] RxD_state = 0;

    `ifdef SIMULATION
    wire RxD_bit = RxD;
    wire sampleNow = 1'b1;

    `else
    wire OversamplingTick;
    BaudTickGen #(ClkFrequency, Baud, Oversampling) tickgen(.clk(clk), .enable(1'b1), .tick(OversamplingTick));

    reg [1:0] RxD_sync = 2'b11;
    always @(posedge clk) if(OversamplingTick) RxD_sync <= {RxD_sync[0], RxD};

    reg [1:0] Filter_cnt = 2'b11;
    reg RxD_bit = 1'b1;

    always @(posedge clk)
    if(OversamplingTick)
    begin
        if(RxD_sync[1]==1'b1 && Filter_cnt!=2'b11) Filter_cnt <= Filter_cnt + 1'd1;
        else
        if(RxD_sync[1]==1'b0 && Filter_cnt!=2'b00) Filter_cnt <= Filter_cnt - 1'd1;

        if(Filter_cnt==2'b11) RxD_bit <= 1'b1;
        else
        if(Filter_cnt==2'b00) RxD_bit <= 1'b0;
    end

    function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction
    localparam l2o = log2(Oversampling);
    reg [l2o-2:0] OversamplingCnt = 0;
    always @(posedge clk) if(OversamplingTick) OversamplingCnt <= (RxD_state==0) ? 1'd0 : OversamplingCnt + 1'd1;
    wire sampleNow = OversamplingTick && (OversamplingCnt==Oversampling/2-1);
    `endif

    always @(posedge clk)
    case(RxD_state)
        4'b0000: if(~RxD_bit) RxD_state <= `ifdef SIMULATION 4'b1000 `else 4'b0001 `endif;
        4'b0001: if(sampleNow) RxD_state <= 4'b1000;
        4'b1000: if(sampleNow) RxD_state <= 4'b1001;
        4'b1001: if(sampleNow) RxD_state <= 4'b1010;
        4'b1010: if(sampleNow) RxD_state <= 4'b1011;
        4'b1011: if(sampleNow) RxD_state <= 4'b1100;
        4'b1100: if(sampleNow) RxD_state <= 4'b1101;
        4'b1101: if(sampleNow) RxD_state <= 4'b1110;
        4'b1110: if(sampleNow) RxD_state <= 4'b1111;
        4'b1111: if(sampleNow) RxD_state <= 4'b0010;
        4'b0010: if(sampleNow) RxD_state <= 4'b0000;
        default: RxD_state <= 4'b0000;
    endcase

    always @(posedge clk)
    if(sampleNow && RxD_state[3]) RxD_data <= {RxD_bit, RxD_data[7:1]};

    always @(posedge clk)
    begin
        RxD_data_ready <= (sampleNow && RxD_state==4'b0010 && RxD_bit);
    end

    `ifdef SIMULATION
    assign RxD_idle = 0;
    `else
    reg [l2o+1:0] GapCnt = 0;
    always @(posedge clk) if (RxD_state!=0) GapCnt<=0; else if(OversamplingTick & ~GapCnt[log2(Oversampling)+1]) GapCnt <= GapCnt + 1'h1;
    assign RxD_idle = GapCnt[l2o+1];
    always @(posedge clk) RxD_endofpacket <= OversamplingTick & ~GapCnt[l2o+1] & &GapCnt[l2o:0];
    `endif

endmodule

module BaudTickGen(
    input clk, enable,
    output tick
);
parameter ClkFrequency = 12000000;
parameter Baud = 115200;
parameter Oversampling = 1;

function integer log2(input integer v); begin log2=0; while(v>>log2) log2=log2+1; end endfunction
localparam AccWidth = log2(ClkFrequency/Baud)+8;
reg [AccWidth:0] Acc = 0;
localparam ShiftLimiter = log2(Baud*Oversampling >> (31-AccWidth));
localparam Inc = ((Baud*Oversampling << (AccWidth-ShiftLimiter))+(ClkFrequency>>(ShiftLimiter+1)))/(ClkFrequency>>ShiftLimiter);
always @(posedge clk) if(enable) Acc <= Acc[AccWidth-1:0] + Inc[AccWidth:0]; else Acc <= Inc[AccWidth:0];
assign tick = Acc[AccWidth];
endmodule
