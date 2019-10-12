// **********************************************************************
// * Project           : urat_axi
// * Program name      : uart to axi controller
// * Author            : jm
// * Date created      : 2019/09/29
// * Abstract          : uart command to axi4 (and burst read) controller
// *                     
// * Revision History  :
// * Date        Author      Ver    Revision
// * 2019/09/29  ypyp3       1      New
// **********************************************************************

module urat_axi_testtop;

    `ifdef DEF_RTL_SIM
parameter integer P_UART_PHASE = 160;
    `else 
parameter integer P_UART_PHASE = 1000000000/112500;
    `endif

// interconnect
// uart
logic           uart_rx;
wire            uart_tx;
// AXI
logic           aclk;       // 100MHz
logic           rstn;       // sync, low active
// AW channel
wire[15:0]      axi_awaddr;
wire[7:0]       axi_awlen;
wire[2:0]       axi_awsize;
wire[1:0]       axi_awburst;
wire            axi_awlock;
wire[3:0]       axi_awcache;
wire[2:0]       axi_awprot;
wire            axi_awvalid;
wire            axi_awready;
// W channel
wire[31:0]      axi_wdata;
wire[3:0]       axi_wstrb;
wire            axi_wlast;
wire            axi_wvalid;
wire            axi_wready;
// B channel
wire[1:0]       axi_bresp;
wire            axi_bvalid;
wire            axi_bready;
// AR channel
wire[15:0]      axi_araddr;
wire[7:0]       axi_arlen;
wire[2:0]       axi_arsize;
wire[1:0]       axi_arburst;
wire            axi_arlock;
wire[3:0]       axi_arcache;
wire[2:0]       axi_arprot;
wire            axi_arvalid;
wire            axi_arready;
// R channel
wire[31:0]      axi_rdata;
wire[1:0]       axi_rresp;
wire            axi_rlast;
wire            axi_rvalid;
wire            axi_rready;

// inst
urat_axi m_DUT(
    // urat
    .i_uart_rx      (uart_rx),
    .o_uart_tx      (uart_tx),
    // AXI master
    .aclk           (aclk),
    .rstn           (rstn),
    // AW channel
    .m_axi_awaddr   (axi_awaddr),
    .m_axi_awlen    (axi_awlen),
    .m_axi_awsize   (axi_awsize),
    .m_axi_awburst  (axi_awburst),
    .m_axi_awlock   (axi_awlock),
    .m_axi_awcache  (axi_awcache),
    .m_axi_awprot   (axi_awprot),
    .m_axi_awvalid  (axi_awvalid),
    .m_axi_awready  (axi_awready),
    // W channel
    .m_axi_wdata    (axi_wdata),
    .m_axi_wstrb    (axi_wstrb),
    .m_axi_wlast    (axi_wlast),
    .m_axi_wvalid   (axi_wvalid),
    .m_axi_wready   (axi_wready),
    // B channel
    .m_axi_bresp    (axi_bresp),
    .m_axi_bvalid   (axi_bvalid),
    .m_axi_bready   (axi_bready),
    // AR channel
    .m_axi_araddr   (axi_araddr),
    .m_axi_arlen    (axi_arlen),
    .m_axi_arsize   (axi_arsize),
    .m_axi_arburst  (axi_arburst),
    .m_axi_arlock   (axi_arlock),
    .m_axi_arcache  (axi_arcache),
    .m_axi_arprot   (axi_arprot),
    .m_axi_arvalid  (axi_arvalid),
    .m_axi_arready  (axi_arready),
    // R channel
    .m_axi_rdata    (axi_rdata),
    .m_axi_rresp    (axi_rresp),
    .m_axi_rlast    (axi_rlast),
    .m_axi_rvalid   (axi_rvalid),
    .m_axi_rready   (axi_rready)
);

axi_bram_slv m_testmem(
  .s_axi_aclk       (aclk),
  .s_axi_aresetn    (rstn),
  .s_axi_awaddr     (axi_awaddr[11:0]),
  .s_axi_awlen      (axi_awlen),
  .s_axi_awsize     (axi_awsize),
  .s_axi_awburst    (axi_awburst),
  .s_axi_awlock     (axi_awlock),
  .s_axi_awcache    (axi_awcache),
  .s_axi_awprot     (axi_awprot),
  .s_axi_awvalid    (axi_awvalid),
  .s_axi_awready    (axi_awready),
  .s_axi_wdata      (axi_wdata),
  .s_axi_wstrb      (axi_wstrb),
  .s_axi_wlast      (axi_wlast),
  .s_axi_wvalid     (axi_wvalid),
  .s_axi_wready     (axi_wready),
  .s_axi_bresp      (axi_bresp),
  .s_axi_bvalid     (axi_bvalid),
  .s_axi_bready     (axi_bready),
  .s_axi_araddr     (axi_araddr[11:0]),
  .s_axi_arlen      (axi_arlen),
  .s_axi_arsize     (axi_arsize),
  .s_axi_arburst    (axi_arburst),
  .s_axi_arlock     (axi_arlock),
  .s_axi_arcache    (axi_arcache),
  .s_axi_arprot     (axi_arprot),
  .s_axi_arvalid    (axi_arvalid),
  .s_axi_arready    (axi_arready),
  .s_axi_rdata      (axi_rdata),
  .s_axi_rresp      (axi_rresp),
  .s_axi_rlast      (axi_rlast),
  .s_axi_rvalid     (axi_rvalid),
  .s_axi_rready     (axi_rready)
);

// clock gen
initial begin
    aclk = 1'b0;
    forever begin
        #(10/2ns);
        aclk <= ~aclk;
    end
end

// scenario
initial begin
    rstn = 0;
    uart_rx = 1'b1;
    #100ns;
    @(posedge aclk) rstn <= 1;
    #100ns;

    // test
    fork
        uart_rcv_dat();
    join_none
    uart_wr_cmd("0FEC", "1234ABCD");
    uart_rd_cmd("0fec");
    uart_wr_cmd("0000", "fedcba98");
    uart_wr_cmd("0004", "01234567");
    uart_wr_cmd("0008", "aaaaaaaa");
    uart_wr_cmd("000c", "ffffffff");
    uart_rb_cmd("0000", "03");
    #80us;

    $finish;
end

task uart_rd_cmd(logic[0:3][0:7] addr);
    logic[0:6][0:7] cmd_arr;
    cmd_arr[0:1] = "r ";
    cmd_arr[2:5] = addr;
    cmd_arr[6]   = 8'h0d;

    for (int i = 0; i < $size(cmd_arr); i++) begin
        uart_sendbyte(cmd_arr[i]);
    end
    $display("sent %02d bytes",$size(cmd_arr));
    $display("sent data (  hex) %h", cmd_arr);
    $display("sent data (ascii) %s", cmd_arr);

endtask : uart_rd_cmd

task uart_rb_cmd(logic[0:3][0:7] addr, logic[0:1][0:7] len);
    logic[0:10][0:7] cmd_arr;
    cmd_arr[0:2] = "br ";
    cmd_arr[3:6] = addr;
    cmd_arr[7]   = " ";
    cmd_arr[8:9] = len;
    cmd_arr[10]  = 8'h0d;

    for (int i = 0; i < $size(cmd_arr); i++) begin
        uart_sendbyte(cmd_arr[i]);
    end
    $display("sent %02d bytes",$size(cmd_arr));
    $display("sent data (  hex) %h", cmd_arr);
    $display("sent data (ascii) %s", cmd_arr);

endtask : uart_rb_cmd

task uart_wr_cmd(logic[0:3][0:7] addr, logic[0:7][0:7] wdat);
    logic[0:15][0:7] cmd_arr;
    cmd_arr[0:1] = "w ";
    cmd_arr[2:5] = addr;
    cmd_arr[6]   = " ";
    cmd_arr[7:14]= wdat;
    cmd_arr[15]  = 8'h0d;

    for (int i = 0; i < $size(cmd_arr); i++) begin
        uart_sendbyte(cmd_arr[i]);
    end
    $display("sent %02d bytes",$size(cmd_arr));
    $display("sent data (  hex) %h", cmd_arr);
    $display("sent data (ascii) %s", cmd_arr);

endtask : uart_wr_cmd

task uart_sendbyte(logic[7:0] txdat);
    uart_rx = 1'b0;
    #(P_UART_PHASE);
    for (int i = 0; i < 8; i++) begin // LSB First
        uart_rx = txdat[i];
        #(P_UART_PHASE);
    end
    uart_rx = 1'b1;
    #(P_UART_PHASE);

endtask : uart_sendbyte

task uart_rcv_dat();
    logic[7:0]  dat_tmp;

    forever begin
        wait(uart_tx===1'b0);
        #(P_UART_PHASE);
        #(10ns);
        for (int i = 0; i < 8; i++) begin // LSB First
            dat_tmp = {uart_tx, dat_tmp[7:1]};
            #(P_UART_PHASE);
        end
        UART_STOPBIT_ERR: assert(uart_tx===1'b1) else $display("ERROR: failed finding stop bit");

        $display("Received Data: %s", dat_tmp);
    end

endtask : uart_rcv_dat

endmodule : urat_axi_testtop
