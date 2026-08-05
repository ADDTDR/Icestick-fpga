//the state machine will first send the init commands to set up the screen, then it will be
//stuck in the send pixels mode and wait the pixels from the outside to send to the screen one by one
// module ST7735(input clk, input [15:0] pixel_write, input wr_en, output reg buffer_free, output reg is_init,
//             output reg spi_clk, output reg spi_mosi, output reg spi_dc, output reg spi_cs, input wire enable);

// time delay values calculated correctly. Look at the adafruit library for specific configurations
module top(
   input clk,
   input RX_FROM_FTDI,
   output spi_cs,
   output spi_clk, 
   output spi_mosi, 
   output spi_dc, 
   output reset
);

localparam USE_UART = 1;
localparam SCREEN_WIDTH = 80;
localparam SCREEN_HEIGHT = 160;
localparam SQUARE_SIZE = 16;
localparam SQUARE_X0 = (SCREEN_WIDTH - SQUARE_SIZE) / 2;
localparam SQUARE_Y0 = (SCREEN_HEIGHT - SQUARE_SIZE) / 2;

wire RxD_data_ready;
wire [7:0] RxD_data;

reg [7:0] pixel_hi_byte;
reg has_pixel_hi_byte;
reg [15:0] uart_pixel_write;
reg uart_wr_en;

reg [15:0] pattern_pixel_write;
reg pattern_wr_en;
reg [8:0] pattern_x;
reg [7:0] pattern_y;
reg pattern_wait_accept;

wire buffer_free;
wire is_init;

wire [15:0] pixel_write_mux;
wire wr_en_mux;

assign pixel_write_mux = USE_UART ? uart_pixel_write : pattern_pixel_write;
assign wr_en_mux = USE_UART ? uart_wr_en : pattern_wr_en;

uart_receiver RX(
   .clk(clk),
   .RxD(RX_FROM_FTDI),
   .RxD_data_ready(RxD_data_ready),
   .RxD_data(RxD_data)
);

always @(posedge clk) begin
   uart_wr_en <= 0;
   pattern_wr_en <= 0;

   if (USE_UART) begin
      if (RxD_data_ready) begin
         if (!has_pixel_hi_byte) begin
            pixel_hi_byte <= RxD_data;
            has_pixel_hi_byte <= 1;
         end else if (buffer_free && is_init) begin
            uart_pixel_write <= {pixel_hi_byte, RxD_data};
            uart_wr_en <= 1;
            has_pixel_hi_byte <= 0;
         end
      end
   end else begin
      if (!pattern_wait_accept) begin
         if (buffer_free && is_init) begin
            if ((pattern_x >= SQUARE_X0) && (pattern_x < (SQUARE_X0 + SQUARE_SIZE)) &&
                (pattern_y >= SQUARE_Y0) && (pattern_y < (SQUARE_Y0 + SQUARE_SIZE))) begin
               pattern_pixel_write <= 16'h0000;
            end else begin
               pattern_pixel_write <= 16'hFFFF;
            end

            pattern_wr_en <= 1;
            pattern_wait_accept <= 1;
         end
      end else if (!buffer_free) begin
         pattern_wait_accept <= 0;

         if (pattern_x == (SCREEN_WIDTH - 1)) begin
            pattern_x <= 0;
            if (pattern_y == (SCREEN_HEIGHT - 1)) begin
               pattern_y <= 0;
            end else begin
               pattern_y <= pattern_y + 1;
            end
         end else begin
            pattern_x <= pattern_x + 1;
         end
      end
   end
end

initial begin
   pixel_hi_byte = 8'h00;
   has_pixel_hi_byte = 0;
   uart_pixel_write = 16'h0000;
   uart_wr_en = 0;
   pattern_pixel_write = 16'hFFFF;
   pattern_wr_en = 0;
   pattern_x = 0;
   pattern_y = 0;
   pattern_wait_accept = 0;
end

ST7735 st7735_display(
   .clk(clk),
   .pixel_write(pixel_write_mux),
   .wr_en(wr_en_mux),
   .buffer_free(buffer_free),
   .is_init(is_init),
   .spi_cs(spi_cs),
   .spi_clk(spi_clk),
   .spi_mosi(spi_mosi),
   .spi_dc(spi_dc),
   .reset(reset)
   );


endmodule

module ST7735(
   input clk,
   input [15:0] pixel_write,
   input wr_en,
   output reg buffer_free,
   output reg is_init,
   output reg spi_clk,
   output reg spi_mosi,
   output reg spi_dc,
   output reg spi_cs,
   output reg reset
);

   parameter FREQ_MAIN_HZ = 12000000; // Pulse width (1/12)us
   parameter FREQ_TARGET_SPI_HZ = 4000000; // Pulse width (1/3)us = (1/3000)ms // Pulse width (1/2)us = (1/2000)ms
   parameter HALF_UART_PERIOD = (FREQ_MAIN_HZ/FREQ_TARGET_SPI_HZ)/2;

   parameter SCREEN_WIDTH = 80; //pixel size displayed on screen
   parameter SCREEN_HEIGHT = 160; //pixel size displayed on screen

   
   reg [3:0] clk_counter_tx;
   reg [24:0] counter_send_interval; //to wait between the commands
   reg [7:0] counter_current_param;

   reg [4:0] current_byte_pos;
   reg [19:0] current_pixel;

   reg [15:0] buffer_pixel_write;

   reg advertise_pixel_consume;
   reg advertise_pixel_consume_buffer;
   reg [15:0] pixel_display;

   reg [5:0] state;
   parameter STATE_IDLE=0, STATE_SEND_SWRESET=STATE_IDLE+1, STATE_INTERVAL_SWRESET=STATE_SEND_SWRESET+1, STATE_SEND_SLPOUT=STATE_INTERVAL_SWRESET+1,
             STATE_INTERVAL_SLPOUT=STATE_SEND_SLPOUT+1, STATE_SEND_PARAMS=STATE_INTERVAL_SLPOUT+1, STATE_SEND_INVCTR=STATE_SEND_PARAMS+1, STATE_SEND_INVCTR_PARAM=STATE_SEND_INVCTR+1,
             STATE_SEND_CMD_PWCTR1=STATE_SEND_INVCTR_PARAM+1, STATE_SEND_PWCTR1_PARAMS=STATE_SEND_CMD_PWCTR1+1,
             STATE_SEND_CMD_PWCTR4=STATE_SEND_PWCTR1_PARAMS+1, STATE_SEND_PWCTR4_PARAMS=STATE_SEND_CMD_PWCTR4+1, STATE_SEND_CMD_PWCTR5=STATE_SEND_PWCTR4_PARAMS+1, STATE_SEND_PWCTR5_PARAMS=STATE_SEND_CMD_PWCTR5+1,
             STATE_SEND_CMD_VMCTR1=STATE_SEND_PWCTR5_PARAMS+1, STATE_SEND_VMCTR1_PARAM=STATE_SEND_CMD_VMCTR1+1,
             STATE_SEND_CMD_INVON=STATE_SEND_VMCTR1_PARAM+1,
             STATE_SEND_CMD_MADCTL=STATE_SEND_CMD_INVON+1, STATE_SEND_MADCTL_PARAM=STATE_SEND_CMD_MADCTL+1,
             STATE_SEND_CMD_COLMOD=STATE_SEND_MADCTL_PARAM+1, STATE_SEND_COLMOD_PARAM=STATE_SEND_CMD_COLMOD+1,
             STATE_SEND_CMD_CASET=STATE_SEND_COLMOD_PARAM+1, STATE_SEND_CASET_PARAMS=STATE_SEND_CMD_CASET+1, STATE_SEND_CMD_RASET=STATE_SEND_CASET_PARAMS+1, STATE_SEND_RASET_PARAMS=STATE_SEND_CMD_RASET+1,
             STATE_SEND_NORON=STATE_SEND_RASET_PARAMS+1, STATE_INTERVAL_NORON=STATE_SEND_NORON+1,
             STATE_SEND_DISPON=STATE_INTERVAL_NORON+1, STATE_INTERVAL_DISPON=STATE_SEND_DISPON+1, STATE_SEND_READ_REQ=STATE_INTERVAL_DISPON+1, STATE_READ_VAL=STATE_SEND_READ_REQ+1,
             STATE_SEND_RAMWR_INIT=STATE_READ_VAL+1,
             STATE_FRAME_INIT=STATE_SEND_RAMWR_INIT+1,
             STATE_SEND_RAMWR=STATE_FRAME_INIT+1,
             STATE_FRAME=STATE_SEND_RAMWR+1, STATE_WAITING_PIXEL=STATE_FRAME+1, STATE_STOP=STATE_WAITING_PIXEL+1;

   parameter [7:0] CMD_SWRESET = 8'h01; //software reset
   parameter [7:0] CMD_SLPOUT = 8'h11; //sleep out
   parameter [7:0] CMD_INVCTR = 8'hb4; //display inversion control
   parameter [7:0] CMD_PARAM_INVCTR = 8'h07; //normal mode 
   parameter [7:0] CMD_PWCTR1 = 8'hC0;
   parameter [7:0] CMD_PARAM1_PWCTR1 = 8'hA2;//8'h82;
   parameter [7:0] CMD_PARAM2_PWCTR1 = 8'h02;
   parameter [7:0] CMD_PARAM3_PWCTR1 = 8'h84;
   parameter [7:0] CMD_PWCTR4 = 8'hC3;
   parameter [7:0] CMD_PARAM1_PWCTR4 = 8'h8A;
   parameter [7:0] CMD_PARAM2_PWCTR4 = 8'h2A;//8'h2E;
   parameter [7:0] CMD_PWCTR5 = 8'hC4;
   parameter [7:0] CMD_PARAM1_PWCTR5 = 8'h8A;
   parameter [7:0] CMD_PARAM2_PWCTR5 = 8'hEE;//8'hAA;
   parameter [7:0] CMD_VMCTR1 = 8'hC5;
   parameter [7:0] CMD_PARAM_VMCTR1 = 8'h0E; 
   parameter [7:0] CMD_INVON = 8'h21;
   parameter [7:0] CMD_MADCTL = 8'h36;
   parameter [7:0] CMD_PARAM_MADCTL = 8'hC8;
   parameter [7:0] CMD_COLMOD = 8'h3A;
   parameter [7:0] CMD_PARAM_COLMOD = 8'h05;

   // x  Top left corner x coordinate
   // y  Top left corner x coordinate
   // w  Width of window
   // h  Height of window
   
   parameter [7:0] CMD_CASET = 8'h2A;
   //start and end of column position to draw on the screen
   //the drawable area is starting at 0 // Rmcd2green160x80 from Adafruit library
   parameter [7:0] CMD_PARAM1_CASET = 8'h00;
   parameter [7:0] CMD_PARAM2_CASET = 8'h1A;
   parameter [7:0] CMD_PARAM3_CASET = 8'h00;
   parameter [7:0] CMD_PARAM4_CASET = 8'h69;// 0x1A..0x69 => 80 columns
   //start and end of row position to draw on the screen
   //the drawable area is starting at 0
   parameter [7:0] CMD_RASET = 8'h2B;
   parameter [7:0] CMD_PARAM1_RASET = 8'h00;
   parameter [7:0] CMD_PARAM2_RASET = 8'h01;
   parameter [7:0] CMD_PARAM3_RASET = 8'h00;
   parameter [7:0] CMD_PARAM4_RASET = 8'hA0;// 0x01..0xA0 => 160 rows

   parameter [7:0] CMD_NORON = 8'h13;
   
   parameter [7:0] CMD_DISPON = 8'h29;
   
   parameter [7:0] CMD_RAMWR = 8'h2C;
   reg reg_valid;



   parameter CMD_SWRESET_DELAY = 300000; //150ms delay (150*2000)
   parameter CMD_SLPOUT_DELAY = 510000; //255ms delay
   parameter CMD_NORON_DELAY = 20000; //10ms delay
   parameter CMD_DISPON_DELAY = 200000; //100ms delay


   reg [23:0] delay_counter;
   reg enable;

   initial begin
      clk_counter_tx = 0;

      current_byte_pos = 7;
      current_pixel = 0;
      counter_send_interval = 0;
      counter_current_param = 0;

      spi_clk = 1;
      spi_mosi = 0;
      spi_dc = 0;
      spi_cs = 1;

      // read_reg = 0;
      reg_valid = 0;
      buffer_pixel_write = 0;

      is_init = 0;

      buffer_free = 1;
      // pixel_write_free = 0;

      advertise_pixel_consume = 0;
      advertise_pixel_consume_buffer = 0;
      pixel_display = 0;

      delay_counter = 0;
      enable <= 0;

      state = STATE_SEND_SWRESET;

      reset = 0;
      spi_dc = 0;
      spi_cs = 1;

   end


   always @(posedge clk) begin // lets do the display reset here

      if(delay_counter < 24'h780000) begin //screen in reset mode
         delay_counter <= delay_counter + 1;
         
         if(delay_counter == 24'h400000) begin
            reset <= 1;
         end
      end else begin
         enable <= 1;
      end
      
   end

   always @(posedge clk)
   begin
      if(enable == 1) begin
         clk_counter_tx <= clk_counter_tx+1;
      end

      //generate clock for the spi
      if(clk_counter_tx == HALF_UART_PERIOD) begin
         clk_counter_tx <= 0;
         spi_clk <= ~spi_clk;
      end

      //read pixel, will be consumed by the SPI state machine
      if(wr_en == 1) begin
         buffer_pixel_write <= pixel_write;
         buffer_free <= 0;
      end

      //get info that the spi has read the buffer (synchronised)
      advertise_pixel_consume_buffer <= advertise_pixel_consume;

      if(advertise_pixel_consume_buffer != advertise_pixel_consume) begin
         buffer_free <= 1;
      end

   end

   always @(negedge spi_clk)
   begin
      spi_dc <= 0; //set mosi as "command"
      spi_cs <= 1;

      current_byte_pos <= current_byte_pos-1;

      case (state) //send the config data, then the screen data
      STATE_SEND_SWRESET : begin
         spi_mosi <= CMD_SWRESET[current_byte_pos];
         spi_cs <= 0;
         if(current_byte_pos == 0) begin
            state <= STATE_INTERVAL_SWRESET;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_SWRESET : begin
         counter_send_interval <= counter_send_interval + 1;
         if(counter_send_interval == (FREQ_TARGET_SPI_HZ/12)) begin //wait 150ms
            state <= STATE_SEND_SLPOUT;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_SLPOUT : begin
         spi_cs <= 0;
         spi_mosi <= CMD_SLPOUT[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INTERVAL_SLPOUT;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_SLPOUT : begin
         counter_send_interval <= counter_send_interval + 1;
         if(counter_send_interval == (FREQ_TARGET_SPI_HZ/4)) begin //wait 500ms
            state <= STATE_SEND_INVCTR;
            counter_current_param <= 0;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_INVCTR : begin
         spi_cs <= 0;
         spi_mosi <= CMD_INVCTR[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_INVCTR_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_INVCTR_PARAM: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         spi_mosi <= CMD_PARAM_INVCTR[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_PWCTR1;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_PWCTR1: begin
         spi_cs <= 0;
         spi_mosi <= CMD_PWCTR1[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_PWCTR1_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_PWCTR1_PARAMS: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_PWCTR1[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_PWCTR1[current_byte_pos];
         end
         if(counter_current_param == 2) begin
            spi_mosi <= CMD_PARAM3_PWCTR1[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 2) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_PWCTR4;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_PWCTR4: begin
         spi_cs <= 0;
         spi_mosi <= CMD_PWCTR4[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_PWCTR4_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_PWCTR4_PARAMS: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_PWCTR4[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_PWCTR4[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 1) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_PWCTR5;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_PWCTR5: begin
         spi_cs <= 0;
         spi_mosi <= CMD_PWCTR5[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_PWCTR5_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_PWCTR5_PARAMS: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_PWCTR5[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_PWCTR5[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 1) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_VMCTR1;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_VMCTR1: begin
         spi_cs <= 0;
         spi_mosi <= CMD_VMCTR1[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_VMCTR1_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_VMCTR1_PARAM: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         spi_mosi <= CMD_PARAM_VMCTR1[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_INVON;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_INVON: begin
         spi_cs <= 0;
         spi_mosi <= CMD_INVON[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_MADCTL;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_CMD_MADCTL: begin
         spi_cs <= 0;
         spi_mosi <= CMD_MADCTL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_MADCTL_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_MADCTL_PARAM: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         spi_mosi <= CMD_PARAM_MADCTL[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_COLMOD;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_COLMOD: begin
         spi_cs <= 0;
         spi_mosi <= CMD_COLMOD[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_COLMOD_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_COLMOD_PARAM: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         spi_mosi <= CMD_PARAM_COLMOD[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_CASET;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_CASET: begin
         spi_cs <= 0;
         spi_mosi <= CMD_CASET[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_CASET_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_CASET_PARAMS: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_CASET[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_CASET[current_byte_pos];
         end
         if(counter_current_param == 2) begin
            spi_mosi <= CMD_PARAM3_CASET[current_byte_pos];
         end
         if(counter_current_param == 3) begin
            spi_mosi <= CMD_PARAM4_CASET[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 3) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_RASET;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_RASET: begin
         spi_cs <= 0;
         spi_mosi <= CMD_RASET[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_SEND_RASET_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_RASET_PARAMS: begin
         spi_cs <= 0;
         spi_dc <= 1; //params are seen as data
         if(counter_current_param == 0) begin
            spi_mosi <= CMD_PARAM1_RASET[current_byte_pos];
         end
         if(counter_current_param == 1) begin
            spi_mosi <= CMD_PARAM2_RASET[current_byte_pos];
         end
         if(counter_current_param == 2) begin
            spi_mosi <= CMD_PARAM3_RASET[current_byte_pos];
         end
         if(counter_current_param == 3) begin
            spi_mosi <= CMD_PARAM4_RASET[current_byte_pos];
         end
         if(current_byte_pos == 0) begin
            counter_current_param <= counter_current_param+1;
            if(counter_current_param == 3) begin
               counter_current_param <= 0;
               if(is_init) begin
                  state <= STATE_SEND_RAMWR;
               end
               else begin
                  state <= STATE_SEND_NORON;
               end
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end

      STATE_SEND_NORON : begin
         spi_cs <= 0;
         spi_mosi <= CMD_NORON[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INTERVAL_NORON;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_NORON : begin
         counter_send_interval <= counter_send_interval + 1;
         if(counter_send_interval == (FREQ_TARGET_SPI_HZ/200)) begin //wait 10ms
            state <= STATE_SEND_DISPON;
            counter_current_param <= 0;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_DISPON : begin
         spi_cs <= 0;
         spi_mosi <= CMD_DISPON[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_INTERVAL_DISPON;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_DISPON : begin
         counter_send_interval <= counter_send_interval + 1;
         if(counter_send_interval == (FREQ_TARGET_SPI_HZ/20)) begin //wait 100ms
            state <= STATE_SEND_RAMWR_INIT;
            counter_current_param <= 0;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_RAMWR_INIT: begin
         spi_cs <= 0;
         spi_mosi <= CMD_RAMWR[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_FRAME_INIT;
            current_byte_pos <= 15;
            counter_send_interval <= 0;
         end
      end

      //will fill the framebuffer in the ST7735 as completely black
      //the ST7735 has more memory (131x131) as it is displayed, but we
      //fill it with black pixels
      STATE_FRAME_INIT: begin
         spi_cs <= 0;
         if(current_byte_pos == 0) begin
            current_byte_pos <= 15;
            current_pixel <= current_pixel + 1;
            if(current_pixel == SCREEN_WIDTH*SCREEN_HEIGHT-1) begin
               current_pixel <= 0;
               state <= STATE_SEND_CMD_CASET; //go back to the CASET param and then draw pixels
               is_init <= 1; //finish the init sequence, advertise to the upper modules
            end
         end
         spi_dc <= 1; //set mosi as "data"
         spi_mosi <= 0; //black
      end

      STATE_SEND_RAMWR: begin
         spi_cs <= 0;
         spi_mosi <= CMD_RAMWR[current_byte_pos];
         if(current_byte_pos == 0) begin
            state <= STATE_WAITING_PIXEL;
            current_byte_pos <= 15;
            counter_send_interval <= 0;
         end
      end
      STATE_WAITING_PIXEL: begin
         spi_cs <= 1;
         if(buffer_free == 0) begin
            state <= STATE_FRAME;
            //consume next pixel and advertise the register system
            pixel_display <= buffer_pixel_write;
            advertise_pixel_consume <= ~advertise_pixel_consume;
            current_byte_pos <= 15;
         end
      end
      STATE_FRAME: begin
         spi_cs <= 0;
         if(current_byte_pos == 0) begin

            current_byte_pos <= 15;
            current_pixel <= current_pixel + 1;
            if(current_pixel == (SCREEN_WIDTH)*(SCREEN_HEIGHT)-1) begin //image finished
               current_pixel <= 0;
               state <= STATE_SEND_RAMWR; //send a new frame
               reg_valid <= 1;
            end
            else begin
               state <= STATE_WAITING_PIXEL;
            end
         end
         spi_dc <= 1; //set mosi as "data"
         spi_mosi <= pixel_display[current_byte_pos];
      end
      STATE_STOP: begin
      end
      endcase
   end
endmodule

////////////////////////////////////////////////////////
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

////////////////////////////////////////////////////////
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
