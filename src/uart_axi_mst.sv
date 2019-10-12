// **********************************************************************
// * Project           : 
// * Program name      : uart_axi
// * Author            : jm
// * Date created      : 2019/09/05
// * Abstract          : uart to axi4 I/F
// *                     axi4 master module
// * Revision History  :
// * Date        Author      Ver    Revision
// * 2019/09/05  ypyp3      1      New
// **********************************************************************

module uart_axi_mst (
    input               clk,            // 100MHz
    input               rstn,           // sync, low active
    // uart tx 
    output              o_tx_vld,
    output  [7:0]       o_tx_dat,
    input               i_tx_busy,
    // uart rx 
    input               i_rx_vld,
    input   [7:0]       i_rx_dat,
    input               i_rx_busy,      // unused
    input               i_rx_stpbt_err, // unused
    // AXI master
    // AW channel
    output  [15:0]      m_axi_awaddr,
    output  [7:0]       m_axi_awlen,
    output  [2:0]       m_axi_awsize,
    output  [1:0]       m_axi_awburst,
    output              m_axi_awlock,
    output  [3:0]       m_axi_awcache,
    output  [2:0]       m_axi_awprot,
    output              m_axi_awvalid,
    input               m_axi_awready,
    // W channel
    output  [31:0]      m_axi_wdata,
    output  [3:0]       m_axi_wstrb,
    output              m_axi_wlast,
    output              m_axi_wvalid,
    input               m_axi_wready,
    // B channel
    input   [1:0]       m_axi_bresp,
    input               m_axi_bvalid,
    output              m_axi_bready,
    // AR channel
    output  [15:0]      m_axi_araddr,
    output  [7:0]       m_axi_arlen,
    output  [2:0]       m_axi_arsize,
    output  [1:0]       m_axi_arburst,
    output              m_axi_arlock,
    output  [3:0]       m_axi_arcache,
    output  [2:0]       m_axi_arprot,
    output              m_axi_arvalid,
    input               m_axi_arready,
    // R channel
    input   [31:0]      m_axi_rdata,
    input   [1:0]       m_axi_rresp,
    input               m_axi_rlast,
    input               m_axi_rvalid,
    output              m_axi_rready
);

// in reg
reg         rx_vld_reg;
reg [7:0]   rx_dat_reg;
always @(posedge clk) begin
    if(~rstn) begin
        rx_vld_reg      <= 1'b0;
        rx_dat_reg      <= 8'h00;
    end 
    else begin
        rx_vld_reg      <= i_rx_vld;
        rx_dat_reg      <= i_rx_dat;
    end
end

// rx decode
reg         rx_dec_vld_reg;
reg [3:0]   rx_hex_reg;
reg [2:0]   rx_com_reg;
reg         rx_hex_dec_err_reg;
reg         rx_com_dec_err_reg;
wire[4:0]   rx_ascii2hex = ascii2hex(rx_dat_reg);
wire[3:0]   rx_ascii2com = ascii2com(rx_dat_reg);
always @(posedge clk) begin
    if(~rstn) begin
        rx_dec_vld_reg <= 1'b0;
        rx_hex_reg <= 4'd0;
        rx_com_reg <= 3'd0;
        rx_hex_dec_err_reg <= 1'b0;
        rx_com_dec_err_reg <= 1'b0;
    end 
    else begin
        rx_dec_vld_reg <= rx_vld_reg;
        rx_hex_reg <= rx_ascii2hex[3:0];
        rx_com_reg <= rx_ascii2com[2:0];
        rx_hex_dec_err_reg <= rx_ascii2hex[4];
        rx_com_dec_err_reg <= rx_ascii2com[3];
    end
end

// ascii to hex
// [4] decode err,  [3:0] data
function [4:0] ascii2hex(input[7:0] char_dat);
    case (char_dat)
        8'h30   : ascii2hex = {1'b0, 4'h0};     // 0
        8'h31   : ascii2hex = {1'b0, 4'h1};     // 1
        8'h32   : ascii2hex = {1'b0, 4'h2};     // 2
        8'h33   : ascii2hex = {1'b0, 4'h3};     // 3
        8'h34   : ascii2hex = {1'b0, 4'h4};     // 4
        8'h35   : ascii2hex = {1'b0, 4'h5};     // 5
        8'h36   : ascii2hex = {1'b0, 4'h6};     // 6
        8'h37   : ascii2hex = {1'b0, 4'h7};     // 7
        8'h38   : ascii2hex = {1'b0, 4'h8};     // 8
        8'h39   : ascii2hex = {1'b0, 4'h9};     // 9
        8'h41   : ascii2hex = {1'b0, 4'ha};     // A
        8'h42   : ascii2hex = {1'b0, 4'hb};     // B
        8'h43   : ascii2hex = {1'b0, 4'hc};     // C
        8'h44   : ascii2hex = {1'b0, 4'hd};     // D
        8'h45   : ascii2hex = {1'b0, 4'he};     // E
        8'h46   : ascii2hex = {1'b0, 4'hf};     // F
        8'h61   : ascii2hex = {1'b0, 4'ha};     // a
        8'h62   : ascii2hex = {1'b0, 4'hb};     // b
        8'h63   : ascii2hex = {1'b0, 4'hc};     // c
        8'h64   : ascii2hex = {1'b0, 4'hd};     // d
        8'h65   : ascii2hex = {1'b0, 4'he};     // e
        8'h66   : ascii2hex = {1'b0, 4'hf};     // f
        default : ascii2hex = {1'b1, 4'h0};     // error
    endcase
endfunction : ascii2hex

// hex to ascii
function [7:0] hex2ascii(input[3:0] hex_dat);
    case (hex_dat)
        4'h0    : hex2ascii = 8'h30;    // 0
        4'h1    : hex2ascii = 8'h31;    // 1
        4'h2    : hex2ascii = 8'h32;    // 2
        4'h3    : hex2ascii = 8'h33;    // 3
        4'h4    : hex2ascii = 8'h34;    // 4
        4'h5    : hex2ascii = 8'h35;    // 5
        4'h6    : hex2ascii = 8'h36;    // 6
        4'h7    : hex2ascii = 8'h37;    // 7
        4'h8    : hex2ascii = 8'h38;    // 8
        4'h9    : hex2ascii = 8'h39;    // 9
        4'ha    : hex2ascii = 8'h41;    // A
        4'hb    : hex2ascii = 8'h42;    // B
        4'hc    : hex2ascii = 8'h43;    // C
        4'hd    : hex2ascii = 8'h44;    // D
        4'he    : hex2ascii = 8'h45;    // E
        default : hex2ascii = 8'h46;    // F 
    endcase
endfunction : hex2ascii


// ascii to command code
// [3]   1'b1 : error
// [2:0] 3'd7 : reserve
// [2:0] 3'd6 : LF
// [2:0] 3'd5 : CR
// [2:0] 3'd4 : space
// [2:0] 3'd3 : B, b
// [2:0] 3'd2 : R, r
// [2:0] 3'd1 : W, w
// [2:0] 3'd0 : reserve
localparam COM_LF = 3'd6;
localparam COM_CR = 3'd5;
localparam COM_SP = 3'd4;
localparam COM_B  = 3'd3;
localparam COM_R  = 3'd2;
localparam COM_W  = 3'd1; /* あとでマージ検討 */
function [3:0] ascii2com(input[7:0] char_dat);
    case (char_dat)
        8'h0a   : ascii2com = {1'b0, 3'd6}; // LF
        8'h0d   : ascii2com = {1'b0, 3'd5}; // CR
        8'h20   : ascii2com = {1'b0, 3'd4}; // space
        8'h42   : ascii2com = {1'b0, 3'd3}; // B
        8'h62   : ascii2com = {1'b0, 3'd3}; // b
        8'h52   : ascii2com = {1'b0, 3'd2}; // R
        8'h72   : ascii2com = {1'b0, 3'd2}; // r
        8'h57   : ascii2com = {1'b0, 3'd1}; // W
        8'h77   : ascii2com = {1'b0, 3'd1}; // w
        default : ascii2com = {1'b1, 3'd0}; // error
    endcase
endfunction : ascii2com


// command receive state flow
typedef enum logic[2:0]{
    ST_IDLE,
    ST_OPCODE,
    ST_ADDR,
    ST_WDAT,
    ST_RLEN,
    ST_RX_DONE
} ST_COM_RX;
ST_COM_RX   st_com_rx_reg;
wire        com_w_vld;
wire        com_r_vld;
wire        com_rb_vld;
wire        axi_start = st_com_rx_reg==ST_RX_DONE;

always @(posedge clk) begin
    if(~rstn) begin
        st_com_rx_reg <= ST_IDLE;
    end
    else if(rx_dec_vld_reg&rx_com_dec_err_reg&rx_hex_dec_err_reg) begin
        st_com_rx_reg <= ST_IDLE;
    end
    else begin
        case (st_com_rx_reg)
            ST_OPCODE : begin
                if(rx_dec_vld_reg&(rx_com_reg==COM_SP)) begin
                    st_com_rx_reg <= ST_ADDR;
                end
            end
            ST_ADDR : begin
                if(rx_dec_vld_reg&(rx_com_reg==COM_SP)&com_w_vld) begin
                    st_com_rx_reg <= ST_WDAT;
                end
                else if(rx_dec_vld_reg&(rx_com_reg==COM_SP)&com_rb_vld) begin
                    st_com_rx_reg <= ST_RLEN;
                end
                else if(rx_dec_vld_reg&(rx_com_reg==COM_CR)&com_r_vld) begin
                    st_com_rx_reg <= ST_RX_DONE;
                end
            end
            ST_WDAT : begin
                if(rx_dec_vld_reg&(rx_com_reg==COM_CR)) begin
                    st_com_rx_reg <= ST_RX_DONE;
                end
            end
            ST_RLEN : begin
                if(rx_dec_vld_reg&(rx_com_reg==COM_CR)) begin
                    st_com_rx_reg <= ST_RX_DONE;
                end
            end
            ST_RX_DONE : begin
                st_com_rx_reg <= ST_IDLE;
            end
            default : begin // ST_IDLE
                // if(rx_dec_vld_reg&(~rx_com_dec_err_reg)) begin
                if(rx_vld_reg&(~rx_ascii2com[3])) begin
                    st_com_rx_reg <= ST_OPCODE;
                end
            end
        endcase
    end
end


// command data ratch
reg [1:0][2:0]  com_reg;
always @(posedge clk) begin
    if(~rstn) begin
        com_reg <= {2{3'b000}};
    end
    else if(st_com_rx_reg==ST_IDLE) begin
        com_reg <= {2{3'b000}};
    end
    else if((st_com_rx_reg==ST_OPCODE)&rx_dec_vld_reg&(rx_com_reg!=COM_SP)) begin
        com_reg <= {com_reg[0], rx_com_reg};
    end
end
assign com_w_vld  = com_reg[0] == COM_W;
assign com_r_vld  = com_reg[0] == COM_R;
assign com_rb_vld = com_reg    == {COM_B, COM_R};

// address data ratch
reg [3:0][3:0]  addr_reg;
// wire[15:0]      addr = addr_reg;
always @(posedge clk) begin
    if(~rstn) begin
        addr_reg <= {4{4'h0}};
    end
    else if(st_com_rx_reg==ST_IDLE) begin
        addr_reg <= {4{4'h0}};
    end
    else if((st_com_rx_reg==ST_ADDR)&rx_dec_vld_reg&(rx_com_reg!=COM_SP)&(rx_com_reg!=COM_CR)) begin
        addr_reg <= {addr_reg[2:0], rx_hex_reg};
    end
end

// write data ratch
reg [7:0][3:0]  wdata_reg;
// wire[31:0]      wdata = wdata_reg;
always @(posedge clk) begin
    if(~rstn) begin
        wdata_reg <= {8{4'h0}};
    end
    else if(st_com_rx_reg==ST_IDLE) begin
        wdata_reg <= {8{4'h0}};
    end
    else if((st_com_rx_reg==ST_WDAT)&rx_dec_vld_reg&(rx_com_reg!=COM_SP)&(rx_com_reg!=COM_CR)) begin
        wdata_reg <= {wdata_reg[6:0], rx_hex_reg};
    end
end

// burst read length ratch
reg [1:0][3:0]  rlen_reg;
always @(posedge clk) begin
    if(~rstn) begin
        rlen_reg <= {2{4'h0}};
    end
    else if(st_com_rx_reg==ST_IDLE) begin
        rlen_reg <= {2{4'h0}};
    end
    else if((st_com_rx_reg==ST_RLEN)&rx_dec_vld_reg&(rx_com_reg!=COM_SP)&(rx_com_reg!=COM_CR)) begin
        rlen_reg <= {rlen_reg[0], rx_hex_reg};
    end
end

// AXI bus master
// write
// note: Bはとりあえず見ない仕様とする

// AW channel
reg [15:0]      axi_awaddr_reg;
reg             axi_awvalid_reg;
assign m_axi_awaddr     = axi_awaddr_reg;
assign m_axi_awlen      = 8'd0;     // word len -1
assign m_axi_awsize     = 3'd2;     // data width, 2^(axsize+3)
assign m_axi_awburst    = 2'd0;     // fixed address
assign m_axi_awlock     = 1'b0;     // AXI4ではサポート外
assign m_axi_awcache    = 4'd0;     // non-bufferable
assign m_axi_awprot     = 3'd0;     // unprivileged access
assign m_axi_awvalid    = axi_awvalid_reg;

always @(posedge clk) begin
    if(~rstn) begin
        axi_awaddr_reg <= 16'd0;
    end
    else if(axi_start) begin
        axi_awaddr_reg <= addr_reg;
    end
end
always @(posedge clk) begin
    if(~rstn) begin
        axi_awvalid_reg <= 1'b0;
    end
    else if(axi_start&com_w_vld) begin
        axi_awvalid_reg <= 1'b1;
    end
    else if(m_axi_awready) begin
        axi_awvalid_reg <= 1'b0;
    end
end

// W channel
reg [31:0]      axi_wdata_reg;
reg             axi_wvalid_reg;
assign m_axi_wdata = axi_wdata_reg;
assign m_axi_wstrb = 4'hf;
assign m_axi_wlast = axi_wvalid_reg;
assign m_axi_wvalid= axi_wvalid_reg;

always @(posedge clk) begin
    if(~rstn) begin
        axi_wdata_reg <= 31'd0;
    end
    else if(axi_start) begin
        axi_wdata_reg <= wdata_reg;
    end
end

always @(posedge clk) begin
    if(~rstn) begin
        axi_wvalid_reg <= 1'b0;
    end
    else if(axi_start&com_w_vld) begin
        axi_wvalid_reg <= 1'b1;
    end
    else if(m_axi_wready) begin
        axi_wvalid_reg <= 1'b0;
    end
end

// B channel
reg             axi_bready_reg;
reg             axi_bvalid_d1_reg;
assign m_axi_bready = axi_bready_reg;

always @(posedge clk) begin
    if(~rstn) begin
        axi_bready_reg <= 1'b0;
        axi_bvalid_d1_reg <= 1'b0;
    end
    else begin
        axi_bready_reg <= {axi_bvalid_d1_reg, m_axi_bvalid}==2'b01;
        axi_bvalid_d1_reg <= m_axi_bvalid;
    end
end

// AR channel
reg [15:0]      axi_araddr_reg;
reg [7:0]       axi_rlen_reg;
reg             axi_arvalid_reg;
assign m_axi_araddr     = axi_araddr_reg;
assign m_axi_arlen      = axi_rlen_reg;     // word len -1
assign m_axi_arsize     = 3'h2;             // data width, 2^(axsize+3)
assign m_axi_arburst    = 2'd1;             // incremental
assign m_axi_arlock     = 1'b0;             // AXI4ではサポート外
assign m_axi_arcache    = 4'h0;             // non-bufferable
assign m_axi_arprot     = 3'h0;             // unprivileged access
assign m_axi_arvalid    = axi_arvalid_reg;

always @(posedge clk) begin
    if(~rstn) begin
        axi_araddr_reg <= 16'h0000;
        axi_rlen_reg   <= 8'h00;
    end 
    else if(axi_start) begin
        axi_araddr_reg <= addr_reg;
        axi_rlen_reg   <= rlen_reg;
    end
end
always @(posedge clk) begin
    if(~rstn) begin
        axi_arvalid_reg <= 1'b0;
    end
    else if(axi_start&(com_r_vld|com_rb_vld)) begin
        axi_arvalid_reg <= 1'b1;
    end
    else if(m_axi_arready) begin
        axi_arvalid_reg <= 1'b0;
    end
end

// R channel
reg [31:0]      axi_rdata_reg;
reg             axi_rvaild_reg;
wire            axi_rvalid_wh = {axi_rvaild_reg, m_axi_rvalid}==2'b01;
reg             axi_rvalid_wh_reg;
assign m_axi_rready = m_axi_rvalid; // axi_rvalid_wh;

always @(posedge clk) begin
    if(~rstn) begin
        axi_rdata_reg <= 32'd0;
    end
    else begin // if(axi_rvalid_wh) begin
        axi_rdata_reg <= m_axi_rdata;
    end
end
always @(posedge clk) begin
    if(~rstn) begin
        axi_rvaild_reg    <= 1'b0;
        axi_rvalid_wh_reg <= 1'b0;
    end
    else begin
        axi_rvaild_reg    <= m_axi_rvalid;
        axi_rvalid_wh_reg <= axi_rvalid_wh;
    end
end

// read data fifo
wire[3:0]       fifo_rdat;
wire            fifo_empty;
reg             fifo_empty_d1_reg;
wire            fifo_empty_we = {fifo_empty_d1_reg, fifo_empty}==2'b10;
reg             fifo_rreq_reg;
sync_fifo_w32x256_r4x2048 m_fifo(
    .clk        (clk),
    .rstn       (rstn),
    // write side
    .i_wvld     (axi_rvaild_reg),   // axi_rvalid_wh_reg),
    .i_wdat     (axi_rdata_reg),
    // read side
    .i_rreq     (fifo_rreq_reg),
    .o_rdat     (fifo_rdat),
    .o_empty    (fifo_empty)
);

always @(posedge clk) begin
    if(~rstn) begin
        fifo_empty_d1_reg <= 1'b1;
    end
    else begin
        fifo_empty_d1_reg <= fifo_empty;
    end
end

reg             tx_busy_d1_reg;
wire            tx_busy_we = {tx_busy_d1_reg, i_tx_busy}==2'b10;
always @(posedge clk) begin
    if(~rstn) begin
        tx_busy_d1_reg <= 1'b0;
    end
    else begin
        tx_busy_d1_reg <= i_tx_busy;
    end
end
always @(posedge clk) begin
    if(~rstn) begin
        fifo_rreq_reg <= 1'b0;
    end
    else if((~i_tx_busy)&fifo_empty_we) begin   // 1st byte
        fifo_rreq_reg <= 1'b1;
    end
    else if((~fifo_empty)&tx_busy_we) begin     // 2nd and latter byte
        fifo_rreq_reg <= 1'b1;
    end
    else begin
        fifo_rreq_reg <= 1'b0;
    end
end

reg [7:0]       tx_dat_reg;
reg             tx_vld_reg;
reg             tx_cr_flg_reg;
assign o_tx_dat = tx_dat_reg;
assign o_tx_vld = tx_vld_reg;
always @(posedge clk) begin
    if(~rstn) begin
        tx_dat_reg <= 8'h00;
        tx_vld_reg <= 1'b0;
        tx_cr_flg_reg <= 1'b1;
    end
    else if(fifo_empty&tx_busy_we&tx_cr_flg_reg) begin  // finished sending last byte
        tx_dat_reg <= 8'h0d;                            // CR
        tx_vld_reg <= 1'b1;
        tx_cr_flg_reg <= 1'b0;
    end
    else begin
        tx_dat_reg <= hex2ascii(fifo_rdat);
        tx_vld_reg <= fifo_rreq_reg;
        tx_cr_flg_reg <= (fifo_rreq_reg)? 1'b1:tx_cr_flg_reg;
    end
end

endmodule
