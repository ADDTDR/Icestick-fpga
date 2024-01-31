module led_mon(
    input clck,
    input [3:0] tx_d,
    output  latchPin,
    output  dataPin,
    output  clockPin   
    );


reg [1:0] state = 'd1;
reg [7:0] tx_buf;
reg [30:0] counter;
reg clock_reg_div_800;
reg dout_reg;
reg latch_reg;
reg [3:0] bit_index = 4'h0;

localparam DONE= 'd0, 
           IDLE= 'd1,
           SEND= 'd2;

 
assign clockPin = (state == SEND) ? clock_reg_div_800 : 1'b0;
assign dataPin =  (state == SEND) ? dout_reg  : 1'b0;
assign latchPin =  latch_reg;

initial
    clock_reg_div_800 <= 0;    
       

always@(posedge (clck)) 
        begin
            if(counter == 399 )
                clock_reg_div_800 <= ~clock_reg_div_800;
            if(counter != 399 ) 
                counter <= counter + 1;
            else 
                counter <= 0;     
        end 


//Generate latch signal for 74hc595,  move data to output reg inside 74hc595  
always@(negedge (clock_reg_div_800))
           if (bit_index < 8)
              latch_reg <= 0;
           else 
              latch_reg <= 1;
               
                
// Calculate running bit index            
always@(negedge (clock_reg_div_800))
           begin 
               if (bit_index != 8) 
                   bit_index <= bit_index + 1; 
               else 
                   bit_index <= 0;                   
           end 
           
always@(negedge clock_reg_div_800)begin
        case(state)
          IDLE:begin
                
                // map input number to binary mask 
                if (tx_d == 0)
                 tx_buf <= 8'b11111011;
                if (tx_d == 1)
                 tx_buf <= 8'b00000011;
                if (tx_d == 2) 
                 tx_buf <= 8'b11110110;            
                if (tx_d == 3 )
                 tx_buf <= 8'b11010111;
                if (tx_d == 4 )
                 tx_buf <= 8'b00001111;
                if (tx_d == 5 )
                 tx_buf <= 8'b11011101;
                if (tx_d == 6 )
                 tx_buf <= 8'b11111101;
                if (tx_d == 7 )
                 tx_buf <= 8'b00010011;
                if (tx_d == 8)
                 tx_buf <= 8'b11111111;
                if (tx_d == 9)
                 tx_buf <= 8'b11011111;
               
                if(bit_index == 8)
                    state <= SEND;
          end 
          
          SEND:begin  
            dout_reg <= (tx_buf & (1 <<  bit_index) ) >> bit_index;
            if (bit_index == 8)
                state <= DONE;            
          end
          
          DONE:begin
            state <= IDLE;
          end 
          
        endcase
    end 
    
endmodule