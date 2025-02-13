
module hcms29xx (
    input CLK_i
);
    

// reg CLK_i = 1'b0;
reg [7:0] data =8'b0;
reg load_data = 1'b1; 
wire ready;
reg cmd = 1'b0;
reg ds_reset = 1'b1;


localparam  DURATION = 10000;


localparam SM_START = 'd0,
           SM_CONFIG_W_1 = 'd1,
           SM_CONFIG_W_2 = 'd2,
           SM_RUN = 'd3;

reg [1:0] sm_state = SM_START;



hcms_serial uut(
    .CLK_i(CLK_i),
    .DATA_i(data),
    .DATA_LOAD(load_data),
    .READY(ready),
    .CMD(cmd),
    .DS_RESET(ds_reset)
);


always @(posedge ready) begin

    case (sm_state)
        SM_START :begin
            sm_state <= SM_CONFIG_W_1;
            ds_reset <= 1'b1;
        end
        SM_CONFIG_W_1: begin
            ds_reset <= 1'b0;
            cmd <= 1'b1;
            sm_state <= SM_CONFIG_W_2;
            data <= 'b10000001;
            load_data = 1'b0;
        end
        SM_CONFIG_W_2: begin
            ds_reset <= 1'b0;
            cmd <= 1'b1;
            sm_state <= SM_RUN;
            data <=  'b01111001;
            load_data = 1'b0;
        end    
        SM_RUN:begin
             ds_reset <= 1'b0;
             cmd <= 1'b0;
             data = data + 1;
             load_data = 1'b0;
        end
    endcase
   
    load_data = 1'b0;
end

always @(negedge ready)begin
    load_data = 1'b1;
end


endmodule


// Send cmd/data byte to hcms29 display 
module hcms_serial (
    // Clock
    input CLK_i,
    // Data to be sent 
    input [7:0] DATA_i,
    // Cntrl 
    input DATA_LOAD,
    input CMD, 
    input DS_RESET,

    // Status
    output reg READY,


    // HCMS29XX connections  
    output reg SER_DATA,
    output REG_SEL,
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
reg [7:0] shiftReg = 'd0;
// Hardware ctrl 
reg CE = 0;
assign SER_CLK = (CE == 1'b1 && DS_RESET == 1'b0 ) ? CLK_i : 1'b1;
assign REG_SEL  = CMD;
assign nRESET = !DS_RESET;
assign nCE = (DS_RESET == 1'b1) ? 1'b1: !CE ;

always @(negedge CLK_i) begin
    
    if (reset) begin
        state <= IDLE;
    end 
    else begin
        case (state)
            IDLE : begin 
                // READY <= 1'b1;
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
                READY <= 0;
                CE <= 1; 

                if (tx_bit_index < 7 )
                    tx_bit_index <= tx_bit_index + 1;
                else
                    state <= DONE;

            end
            DONE : begin
                // Transmit finalized set ce to 0
                CE <= 0; 
                READY <= 1;
         
    	        // Wait for ! data load
                if(DATA_LOAD == 1'b0)begin
                    READY <= 1'b0; 
                    state <= IDLE;
                end
            end
            
        endcase
    end
end
endmodule