`timescale 1ns/10ps


module top_tb();

reg CLK_i = 1'b0;
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


always begin
    // Delay 
    #41.667
    CLK_i = ~CLK_i;
end



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

// initial begin
//    #(1 * 41.67)
//     load_data = 1'b0; 	
//    #(10 * 41.67)
//     data = 8'h04;
//     load_data = 1'b1;     
// //     // Clear read addr and enable  signal 
//     // #(10 * 41.67)
//     // data = 8'h32;
//     // load_data = 1'b0;

//     // #(10 * 41.67)
//     // data = 8'h64;
//     // load_data = 1'b1;  
// end

initial begin

 
     $dumpfile("hcms_29xx_tb.vcd");
     $dumpvars(0, top_tb );

     #(DURATION)
     $display("Finished!");
     $finish;
end

endmodule