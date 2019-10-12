// **********************************************************************
// * Project           : 
// * Program name      : uart_axi
// * Author            : jm
// * Date created      : 2019/09/23
// * Abstract          : write: 32x256, read: 4x2048 FWFT
// *                     fifo wrapper
// * Revision History  :
// * Date        Author      Ver    Revision
// * 2019/09/05  ypyp3      1      New
// **********************************************************************

module sync_fifo_w32x256_r4x2048 (
    input               clk,
    input               rstn,
    // write side I/F
    input               i_wvld,
    input   [31:0]      i_wdat,
    output              o_full,
    // read side I/F
    input               i_rreq,
    output  [3:0]       o_rdat,
    output              o_empty
);

// note: based on Xilinx FOFO generator
fifo_w32x256_r4x2048 m_fifo_ip (
    .clk    (clk),
    .srst   (~rstn),
    .din    (i_wdat),
    .wr_en  (i_wvld),
    .full   (o_full),
    .rd_en  (i_rreq),
    .dout   (o_rdat),
    .empty  (o_empty)
);

endmodule
