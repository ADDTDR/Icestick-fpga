// Send cmd/data byte to hcms29 display 
module hcms_serial (
    // Clock
    input CLK_i,
    // Data to be sent 
    input [7:0] DATA_i,
    // Cntrl 
    input DATA_LOAD,
    output reg TX_DONE,


    // HCMS29XX connections  
    output reg SER_DATA,
    output RSEL,
    output SER_CLK,
    output nCE,
    output nRESET


);
    
// Reset signal 
reg  reset = 1'b0;

// SM states 
localparam  IDLE = 'd0,
            SEND = 'd1,
            DONE = 'd2; 

// FSM Reg
reg [1:0] state = IDLE;

// Transmit logic ctr reg's 
reg [2:0] tx_bit_index;
reg [7:0] shiftReg;
// Hardware ctrl 
reg CE = 0;
assign SER_CLK = (CE == 1'b1) ? CLK_i : 1'b1;

always @(negedge CLK_i) begin
    
    if (reset) begin
        state <= IDLE;
    end 
    else begin
        case (state)
            IDLE : begin 
                if (DATA_LOAD == 1'b1) begin 
                state <= SEND;
                tx_bit_index <= 0;
                shiftReg <= DATA_i;
                end
            end
            SEND : begin 
                // SET CE while transmitting 
                SER_DATA <= shiftReg[7];
                shiftReg <= {shiftReg[7:0], 1'b0};
                TX_DONE <= 0;
                CE <= 1; 

                if (tx_bit_index < 7 )
                    tx_bit_index <= tx_bit_index + 1;
                else
                    state <= DONE;

            end
            DONE : begin
                // Transmit finalized set ce to 0
                CE <= 0; 
                TX_DONE <= 1;
                // state <= IDLE;

                if(DATA_LOAD == 1'b0)begin
                    TX_DONE <= 1'b0; 
                    state <= IDLE;
                end
            end
            
        endcase
    end
end
endmodule