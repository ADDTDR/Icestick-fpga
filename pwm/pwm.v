module top(
    input CLK_i,
    output D1,
    output D2, 
    output D3,
    output D4,
    output D5
);
    reg [17:0] clock;
    reg div_clk;
    reg [7:0] pwm_duty;
    initial
        pwm_duty <= 8'h00;

    always@(posedge CLK_i)begin 
      clock <= clock + 1;
      div_clk <= clock[17];
    end 
 
 
    always@(negedge div_clk)begin
          if (pwm_duty == 255)
            pwm_duty <= 0;
          else   
            pwm_duty <= pwm_duty + 1;
    end  


    PWM pwm(
        .clk(CLK_i),
        .PWM_in(pwm_duty),
        .PWM_out(D1)
    );

    assign D2 = 0;
    assign D3 = 0;
    assign D4 = 0;
    assign D5 = 0;
endmodule

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