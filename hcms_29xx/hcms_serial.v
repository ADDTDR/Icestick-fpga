
module top (
    input i_clk,
    output PMOD_1,
    output PMOD_2,
    output PMOD_3,
    output PMOD_4,
    output PMOD_5
);

reg [20:0] counter = 0;

always @(posedge i_clk)
    counter <= counter + 1;

hcms29xx display(
    .i_CLK(counter[2]),
    .o_hcms_data(PMOD_1),
    .o_hcms_clock(PMOD_2),
    .o_hcms_regsel(PMOD_3),
    .o_hcms_ncs(PMOD_4),
    .o_hcms_reset(PMOD_5)

);
endmodule

module hcms29xx (
    input  i_CLK,
    output o_hcms_data,
    output o_hcms_clock,
    output o_hcms_regsel,
    output o_hcms_ncs,
    output o_hcms_reset
);
    

reg [7:0] r_data =8'b0;
reg r_load_data = 1'b1; 
wire w_ready;
reg r_cmd = 1'b0;
reg r_ds_reset = 1'b1;
reg [7:0] r_bar_counter = 'd0;
reg [7:0] r_latch_counter = 'd0;

reg [7:0]  mem [0:20];

initial begin
    mem[0]  = 8'h7E; mem[1]  = 8'h11; mem[2]  = 8'h11; mem[3]  = 8'h11; mem[4]  = 8'h7E; // A
    mem[5]  = 8'h7F; mem[6]  = 8'h49; mem[7]  = 8'h49; mem[8]  = 8'h49; mem[9]  = 8'h36; // B
    mem[10] = 8'h3E; mem[11] = 8'h41; mem[12] = 8'h41; mem[13] = 8'h41; mem[14] = 8'h22; // C
    mem[15] = 8'h7F; mem[16] = 8'h41; mem[17] = 8'h41; mem[18] = 8'h22; mem[19] = 8'h1C; // D
end

localparam HCMS_DATA_REGISTER = 1'b0,
           HCMS_COMMAND_REGISTER = 1'b1;



localparam SM_START = 'd0,
           SM_CONFIG_W_1 = 'd1,
           SM_CONFIG_W_2 = 'd2,
           SM_RUN = 'd3;

reg [1:0] sm_state = SM_START;
reg latch_enable;

always @(posedge i_CLK)
 r_load_data <= !w_ready;

hcms_serial hcms29_serial(
    .i_CLK(i_CLK),
    .i_data(r_data),
    .i_data_load(r_load_data),
    .o_r_ready(w_ready),
    .i_cmd(r_cmd),
    .i_hcms_reset(r_ds_reset),
    .i_latch_enable(latch_enable),

    .o_r_serial_data(o_hcms_data),
    .o_register_sel(o_hcms_regsel),
    .o_serial_clk(o_hcms_clock),
    .o_nCe(o_hcms_ncs),
    .o_nReset(o_hcms_reset)

);


always @(posedge w_ready) begin

    case (sm_state)
        SM_START :begin
            sm_state <= SM_CONFIG_W_1;
            r_ds_reset <= 1'b1;
        end
        SM_CONFIG_W_1: begin
            r_ds_reset <= 1'b0;
            r_cmd <= HCMS_COMMAND_REGISTER;
            sm_state <= SM_CONFIG_W_2;
            r_data <= 'b10000001;
            latch_enable <= 1'b1;
        end
        SM_CONFIG_W_2: begin
            r_ds_reset <= 1'b0;
            r_cmd <= HCMS_COMMAND_REGISTER;
            sm_state <= SM_RUN;
            r_data <=  'b01111111;
            latch_enable <= 1'b1;
            r_latch_counter <= 0;
        end    
        SM_RUN:begin
            // (5C X 7R) X 4
            // 5C X 4 - 1
            if (r_latch_counter == 19)begin
                r_data <= mem[r_latch_counter ];
                r_latch_counter <= 0;
                latch_enable <= 1'b1;
                
            end    
   
            else begin
                r_bar_counter <= r_bar_counter + 1;
                r_latch_counter <= r_latch_counter + 1;
                r_ds_reset <= 1'b0;
                r_cmd <= HCMS_DATA_REGISTER;
                // r_data = r_data << 1;
                r_data = mem[r_latch_counter ];
                latch_enable <= 1'b0;
                   
            end
          
            
        end
    endcase

end


endmodule


// Send cmd/data byte to hcms29 display 
module hcms_serial (
    // Clock
    input i_CLK,
    // Data to be sent 
    input [7:0] i_data,

    // Cntrl 
    input i_data_load,
    input i_cmd, 
    input i_hcms_reset,
    input i_latch_enable,

    // Status
    output reg o_r_ready,

    // hcms serial  interface  connections  
    output reg o_r_serial_data,
    output o_register_sel,
    output o_serial_clk,
    output o_nCe,
    output o_nReset


);
    
// Reset signal 
reg  r_reset = 1'b0;

// SM states 
localparam  IDLE = 'd0,
            SEND = 'd1,
            DONE = 'd2; 

// FSM Reg
reg [1:0] r_state = IDLE;

// Transmit logic ctr reg's 
reg [2:0] r_tx_bit_index = 'd0;
reg [7:0] r_shift_register = 'd0;

// Hardware ctrl 
reg CE = 0;
assign o_serial_clk = (CE == 1'b1 && i_hcms_reset == 1'b0 ) ? i_CLK : 1'b0;
assign o_register_sel  = i_cmd;
assign o_nReset = !i_hcms_reset;
assign o_nCe = (i_hcms_reset == 1'b1) ? 1'b1: !CE && i_latch_enable ;

always @(negedge i_CLK) begin
    
    if (r_reset) begin
        r_state <= IDLE;
    end 
    else begin
        case (r_state)
            IDLE : begin 
                if (i_data_load == 1'b1) begin 
                r_state <= SEND;
                r_tx_bit_index <= 0;
                r_shift_register <= i_data;
                end
            end
            SEND : begin 
                // SET CE while transmitting 
                o_r_serial_data <= r_shift_register[7];
                r_shift_register <= {r_shift_register[7:0], 1'b0};
                o_r_ready <= 0;
                CE <= 1; 

                if (r_tx_bit_index < 7 )
                    r_tx_bit_index <= r_tx_bit_index + 1;
                else
                    r_state <= DONE;

            end
            DONE : begin
                // Transmit finalized set ce to 0
                CE <= 0; 
                o_r_ready <= 1;
         
    	        // Wait for ! data load
                if(i_data_load == 1'b0)begin
                    o_r_ready <= 1'b0; 
                    r_state <= IDLE;
                end
            end
            
        endcase
    end
end
endmodule