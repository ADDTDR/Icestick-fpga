module top(
    input CLK_i,
    output PMOD_2,
    output PMOD_3,
    output PMOD_4
   
    );
    
reg [27:0] clock = 0; 
reg cc; 

reg [3:0] tx_d = 4'h0;
reg [3:0] i = 3'b0;


led_mon LDM (
    .clck(CLK_i),
    .tx_d(tx_d),
    .latchPin(PMOD_3),
    .dataPin(PMOD_2),
    .clockPin(PMOD_4)
    ); 
    
    
  always@(posedge CLK_i)begin 
      clock <= clock + 1;
      cc <= clock[23];
   end 
 
 
     always@(negedge cc)
        begin
          tx_d <= i;
          if (i == 9)
            i <= 0;
          else   
            i <= i + 1;
         end  
endmodule