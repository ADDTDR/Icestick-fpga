module PWM (
    input clk, 
    input [7:0] PWM_in,
    output PWM_out
);

    reg [8:0]   PWM_accumulator;

    initial
        PWM_accumulator <= 0;

    always @(posedge clk) begin
        PWM_accumulator <= PWM_accumulator[7:0] + PWM_in;
    end
    assign PWM_out = PWM_accumulator[8];
endmodule