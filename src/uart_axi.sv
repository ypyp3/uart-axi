// **********************************************************************
// * Project           : 
// * Program name      : uart_axi
// * Author            : jm
// * Date created      : 2019/09/05
// * Abstract          : uart to axi4 I/F 
// *                     TOP
// * Revision History  :
// * Date        Author      Ver    Revision
// * 2019/09/05  ypyp3      1      New
// **********************************************************************

module uart_axi (
    // urat
    input               i_uart_rx,
    output              o_uart_tx,
    // AXI master
    input               aclk,       // 100MHz
    input               rstn,       // sync, low active
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

// uart front end
wire        tx_vld;
wire[7:0]   tx_dat;
wire        tx_busy;
wire        rx_vld;
wire[7:0]   rx_dat;
wire        rx_busy;
wire        rx_stpbt_err;
uart_trx #(
    .P_BAUD_RATE    (115200)
) m_uart_trx(
    .clk            (aclk),
    .rstn           (rstn),
    // uart IO
    .i_uart_rx      (i_uart_rx),
    .o_uart_tx      (o_uart_tx),
    // tx
    .i_tx_vld       (tx_vld),
    .i_tx_dat       (tx_dat),
    .o_tx_busy      (tx_busy),
    // rx
    .o_rx_vld       (rx_vld),
    .o_rx_dat       (rx_dat),
    .o_rx_busy      (rx_busy),
    .o_rx_stpbt_err (rx_stpbt_err)
);


uart_axi_mst m_uart_axi_mst(
    .clk            (aclk),
    .rstn           (rstn),
    // uart tx
    .o_tx_vld       (tx_vld),
    .o_tx_dat       (tx_dat),
    .i_tx_busy      (tx_busy),
    // uart rx
    .i_rx_vld       (rx_vld),
    .i_rx_dat       (rx_dat),
    .i_rx_busy      (rx_busy),
    .i_rx_stpbt_err (rx_stpbt_err),
    // AXI master
    // AW channel
    .m_axi_awaddr   (m_axi_awaddr),
    .m_axi_awlen    (m_axi_awlen),
    .m_axi_awsize   (m_axi_awsize),
    .m_axi_awburst  (m_axi_awburst),
    .m_axi_awlock   (m_axi_awlock),
    .m_axi_awcache  (m_axi_awcache),
    .m_axi_awprot   (m_axi_awprot),
    .m_axi_awvalid  (m_axi_awvalid),
    .m_axi_awready  (m_axi_awready),
    // W channel
    .m_axi_wdata    (m_axi_wdata),
    .m_axi_wstrb    (m_axi_wstrb),
    .m_axi_wlast    (m_axi_wlast),
    .m_axi_wvalid   (m_axi_wvalid),
    .m_axi_wready   (m_axi_wready),
    // B channel
    .m_axi_bresp    (m_axi_bresp),
    .m_axi_bvalid   (m_axi_bvalid),
    .m_axi_bready   (m_axi_bready),
    // AR channel
    .m_axi_araddr   (m_axi_araddr),
    .m_axi_arlen    (m_axi_arlen),
    .m_axi_arsize   (m_axi_arsize),
    .m_axi_arburst  (m_axi_arburst),
    .m_axi_arlock   (m_axi_arlock),
    .m_axi_arcache  (m_axi_arcache),
    .m_axi_arprot   (m_axi_arprot),
    .m_axi_arvalid  (m_axi_arvalid),
    .m_axi_arready  (m_axi_arready),
    // R channel
    .m_axi_rdata    (m_axi_rdata),
    .m_axi_rresp    (m_axi_rresp),
    .m_axi_rlast    (m_axi_rlast),
    .m_axi_rvalid   (m_axi_rvalid),
    .m_axi_rready   (m_axi_rready)
);


endmodule
