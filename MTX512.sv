//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


module MTX512
(       
        output        LED,                                              
        output        VGA_HS,
        output        VGA_VS,
        output        AUDIO_L,
        output        AUDIO_R, 
		  output [15:0]  DAC_L, 
		  output [15:0]  DAC_R, 
        input         TAPE_IN,
        input         UART_RX,
        output        UART_TX,
        input         SPI_SCK,
        output        SPI_DO,
        input         SPI_DI,
        input         SPI_SS2,
        input         SPI_SS3,
        input         CONF_DATA0,
        input         CLOCK_27,
        output  [5:0] VGA_R,
        output  [5:0] VGA_G,
        output  [5:0] VGA_B,

		  output [12:0] SDRAM_A,
		  inout  [15:0] SDRAM_DQ,
		  output        SDRAM_DQML,
        output        SDRAM_DQMH,
        output        SDRAM_nWE,
        output        SDRAM_nCAS,
        output        SDRAM_nRAS,
        output        SDRAM_nCS,
        output  [1:0] SDRAM_BA,
        output        SDRAM_CLK,
        output        SDRAM_CKE
);


 


`include "build_id.v" 
localparam CONF_STR = {
        "MTX512;;",
		  "O4,Video Out,80Col,VDP;",
        "S0,IMGVHD,Load VHD;",
		  "F0,ROM,Load ROM;",
        "O2,PAL,Normal,Marat;",
        "O3,Hz,60,50;",
        "O57,Cpu Mzh,25,12.5,8.333,6.25,5,4.166,3.571,3.125;",
        "T0,Reset;",
        "V,v",`BUILD_DATE 
};

/////////////////  CLOCKS  ////////////////////////

wire clk_25Mhz,clk_ram,clk_ram_ph,locked,CLK_50;

pll pll
(
	.inclk0(CLOCK_27),
	.c0(CLK_50),
	.c1(clk_ram),
	.c2(clk_ram_ph),
	.locked(locked)
);


///////////////// SDRAM ///////////////////////////

wire [22:0] sramAddress;
wire [7:0]  sramData;
wire [7:0]  sramDataIn;
wire [7:0]  sramDataOut;


wire n_sRamWE;
wire n_sRamOE;
wire n_sRamCS;

//assign SDRAM_CLK=clk_ram_ph;
//ssdram ram
//(
//  .clock_i   (clk_ram),
//  .reset_i   (~locked),
//  .refresh_i (1'b1),
//  //
//  .addr_i     (ioctl_download ? ioctl_addr : sramAddress),
//  .data_i     (ioctl_download ? ioctl_data : sramDataIn ),
//  .data_o     (sramDataOut),
//  .cs_i       (1'b1),
//  .oe_i       (1'b1),
//  .we_i       (ioctl_download ? ioctl_wr : ~n_sRamWE),
//  //
//  .mem_cke_o    (SDRAM_CKE),
//  .mem_cs_n_o   (SDRAM_nCS),
//  .mem_ras_n_o  (SDRAM_nRAS),
//  .mem_cas_n_o  (SDRAM_nCAS),
//  .mem_we_n_o   (SDRAM_nWE),
//  .mem_udq_o    (SDRAM_DQMH),
//  .mem_ldq_o    (SDRAM_DQML),
//  .mem_ba_o     (SDRAM_BA),
//  .mem_addr_o   (SDRAM_A),
//  .mem_data_io  (SDRAM_DQ)
//);

wire ram_ready;
sram ram
(
	.*,
	.init(~locked),
	.clk(clk_ram),	
	.addr(ioctl_download ? ioctl_addr: sramAddress),
	.dout(sramDataOut),
	.din(ioctl_download ? ioctl_data : sramDataIn),
	.wtbt(2'b00),
	.we(ioctl_download ? ioctl_wr    : ~n_sRamWE),
	.rd(ioctl_download ? 1'b0        : ~n_sRamOE),
	.ready(ram_ready)
);
assign SDRAM_CLK=clk_ram_ph;
/////////////////  HPS  ///////////////////////////


wire forced_scandoubler;
wire  [1:0] buttons;
wire [31:0] status;
wire [10:0] ps2_key;
wire        ioctl_download;
wire        ioctl_wr;
wire [18:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire  [7:0] ioctl_index;

wire [31:0] joy1, joy2;

wire ypbpr;

wire        img_readonly;
wire  [1:0] img_mounted;
wire [31:0] img_size;

wire [31:0] sd_lba;
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        sd_ack_conf;
wire        Ps2_Clk;
wire        Ps2_Dat;


 
mist_io #(.STRLEN($size(CONF_STR)>>3),.PS2DIV(100)) mist_io
(
	.SPI_SCK   (SPI_SCK),
   .CONF_DATA0(CONF_DATA0),
   .SPI_SS2   (SPI_SS2),
   .SPI_DO    (SPI_DO),
   .SPI_DI    (SPI_DI),

	.clk_sys(clk_25Mhz),
	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.scandoubler_disable(forced_scandoubler),
   .ypbpr     (ypbpr),
	
	.ioctl_ce(1),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
		
	 .sd_sdhc(sdhc),
	 .sd_conf(0),
	 .sd_lba(sd_lba),
	 .sd_rd(sd_rd),
	 .sd_wr(sd_wr),
	 .sd_ack(sd_ack),
	 .sd_ack_conf(sd_ack_conf),
	 .sd_buff_addr(sd_buff_addr),
	 .sd_buff_dout(sd_buff_dout),
	 .sd_buff_din(sd_buff_din),
	 .sd_buff_wr(sd_buff_wr),
	 .img_mounted(img_mounted),
	 .img_size(img_size),

	 .ps2_kbd_clk(Ps2_Clk),
	 .ps2_kbd_data(Ps2_Dat),
    .ps2_key(ps2_key),

	.joystick_0(joy1), // HPS joy [4:0] {Fire, Up, Down, Left, Right}
	.joystick_1(joy2)

);

/////////////////  RESET  /////////////////////////
wire reset;
wire old_dio;
always @(posedge clk_25Mhz) begin
	old_dio <= ioctl_download;
	reset <= (!locked | status[0] | buttons[1] | ioctl_download);
end

//////////////// LED ///////////////////////////
//assign LED=reset;

////////////////  main  ////////////////////////


dac_dsm2v #(8) dac_l (
   .clock_i      (clk_25Mhz),
   .reset_i      (0      ),
   .dac_i        (AudioOut),
   .dac_o        (AUDIO_L)
);

assign DAC_L=AudioOut;
assign DAC_R=AudioOut;
assign AUDIO_R=AUDIO_L;

wire HBlank;
wire HSync;
wire VBlank;
wire VSync;



wire [2:0] CpuSpeed = status[7:5];



rememotech rememotech
    (
    .CLOCK_50            (CLK_50),//(clk),//(status[9]),//(CLK_50M),
    // SD card
    .SD_CLK              (sdclk),
    .SD_CMD              (sdmosi),
    .SD_DAT              (vsdmiso),
    .SD_DAT3             (sdss),
    // SDRAM
	 .SRAM_CE_N           (n_sRamCS),
    .SRAM_ADDR           (sramAddress),
    .SRAM_LB_N           (),
    .SRAM_UB_N           (),
    .SRAM_OE_N           (n_sRamOE),
    .SRAM_WE_N           (n_sRamWE),
    .SRAM_D              (sramDataIn),
	 .SRAM_Q              (sramDataOut),
    .LED                 (LED),
    // PS/2 keyboard
    .PS2_CLK             (Ps2_Clk),
    .PS2_DAT             (Ps2_Dat),
    // switches
    .SW                  ({CpuSpeed,status[4],status[2],~status[3],2'b0,2'b0}), //Forzamos monitor(6), Pal normal-60Hz(5:4), y sin externalrom(1:0)
    // key switches
    .KEY                 ({reset,3'b111}),
    // VGA output
    .VGA_R               (r),
    .VGA_G               (g),
    .VGA_B               (b),
    .VGA_HS              (HSync),
    .VGA_VS              (VSync),
 	 .VGA_HB              (HBlank),
	 .VGA_VB              (VBlank),

	 .Clk_Video           (clk_25Mhz),
 
	 
	 .EKey                (status[9]),
    .key_ready           (key_strobe),//key_ready), //: in  std_logic;
    .key_stroke          (~ps2_key[9]), //: in  std_logic;
    .key_code            ({1'b0,ps2_key[8:0]}), //: in  std_logic_vector(9 downto 0)
    .clk_sys             (clk_sys),
    .sound_out           (AudioOut)
);

wire clk_sys;
wire [7:0] AudioOut;
wire key_strobe = old_keystb ^ ps2_key[10];
reg old_keystb = 0;
always @(posedge clk_25Mhz) old_keystb <= ps2_key[10];



/////////////////  VIDEO  /////////////////////////

wire [3:0] r,g,b;

	
video_mixer #(.LINE_LENGTH(380)) video_mixer
(
   .*,
	.clk_sys(clk_25Mhz),
   .ce_pix(clk_25Mhz),
   .ce_pix_actual(clk_25Mhz),
   .scandoubler_disable(1),
   .hq2x(0),
   .mono(0),
   .scanlines(0),
   .ypbpr_full(0),
   .line_start(0),
	.VGA_HS(),
	.VGA_VS(),
	.R({r,r[3:2]}),
	.G({g,g[3:2]}),
   .B({b,b[3:2]})
);

assign VGA_VS=~VSync;
assign VGA_HS=~HSync;

/////////////////  Tape In   /////////////////////////

wire tape_in;
assign tape_in = UART_RX;
//////////////////   SD   ///////////////////

wire sdclk;
wire sdmosi;
wire sdss;

wire vsdmiso;
wire sdhc=1'b0;

sd_card sd_card
(
        .*,
		  .clk_sys(CLK_50),
        .clk_spi(clk_ram_ph), 
        .sdhc(sdhc),
        .sck(sdclk),
        .ss(sdss),
        .mosi(sdmosi),
        .miso(vsdmiso)
);


endmodule