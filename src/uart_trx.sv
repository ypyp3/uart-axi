// **********************************************************************
// * Project           : 
// * Program name      : uart_trx, uart_tx, uart_rx
// * Author            : jm
// * Date created      : 2019/09/07
// * Abstract          : UART I/F
// *                     
// * Revision History  :
// * Date        Author      Ver    Revision
// * 2019/09/07  ypyp3      1      New
// **********************************************************************


function [9:0] baud_cntr_limit_100m (input baud_rate);

    `ifdef DEF_RTL_SIM
baud_cntr_limit_100m = 10'd16 - 10'd1;
    `else 
// とりあえず100MHzカウンタ想定
case (baud_rate)
    230400  : baud_cntr_limit_100m = 10'd434 - 10'd1;
    460800  : baud_cntr_limit_100m = 10'd217 - 10'd1;
    921600  : baud_cntr_limit_100m = 10'd108 - 10'd1;
    default : baud_cntr_limit_100m = 10'd868 - 10'd1; // 115200
endcase
    `endif

endfunction : baud_cntr_limit_100m


// UART TX, RX wrapper
module uart_trx #(
    P_BAUD_RATE = 115200
)(
    // system
    input               clk,        // 100MHz
    input               rstn,       // sync, low active
    // uart IO
    output              o_uart_tx,
    input               i_uart_rx,
    // tx I/F
    input               i_tx_vld,
    input   [7:0]       i_tx_dat,
    output              o_tx_busy,
    // rx I/F
    output              o_rx_vld,
    output  [7:0]       o_rx_dat,
    output              o_rx_busy,
    output              o_rx_stpbt_err
);

uart_tx #(
    .P_BAUD_RATE(P_BAUD_RATE)
) m_uart_tx(
    .clk            (clk),
    .rstn           (rstn),
    .o_uart_tx      (o_uart_tx),
    .i_vld          (i_tx_vld),
    .i_dat          (i_tx_dat),
    .o_busy         (o_tx_busy)
);

uart_rx #(
    .P_BAUD_RATE(P_BAUD_RATE)
) m_uart_rx(
    .clk            (clk),
    .rstn           (rstn),
    .i_uart_rx      (i_uart_rx),
    .o_vld          (o_rx_vld),
    .o_dat          (o_rx_dat),
    .o_busy         (o_rx_busy),
    .o_stpbt_err    (o_rx_stpbt_err)
);

endmodule : uart_trx


module uart_tx #(
    P_BAUD_RATE = 115200
)(
    // system
    input               clk,    // 100MHz
    input               rstn,   // sync, high active
    // uart IO
    output              o_uart_tx,
    // tx I/F
    input               i_vld,
    input   [7:0]       i_dat,
    output              o_busy
);

// in reg  ##単独利用も想定
reg             tx_vld_reg;
reg [7:0]       tx_dat_reg;
always @(posedge clk) begin
    if(~rstn) begin
        tx_vld_reg <= 1'b0;
        tx_dat_reg <= 8'h00;
    end 
    else begin
        tx_vld_reg <= i_vld;
        tx_dat_reg <= i_dat;
    end
end

// state
typedef enum logic[1:0]{
    ST_IDLE,
    ST_START_BIT,
    ST_DAT,
    ST_STOP_BIT
} ST_UART_TX;
ST_UART_TX      state_reg;
reg [2:0]       bit_cntr_reg;
reg [9:0]       phase_cntr_reg;
wire            phase_cntr_end  = phase_cntr_reg == baud_cntr_limit_100m(P_BAUD_RATE);

always @(posedge clk) begin
    if(~rstn) begin
        state_reg <= ST_IDLE;
    end 
    else begin
        case (state_reg)
            ST_START_BIT : begin
                if(phase_cntr_end) begin
                    state_reg <= ST_DAT;
                end
            end
            ST_DAT : begin
                if(phase_cntr_end&(&bit_cntr_reg)) begin
                    state_reg <= ST_STOP_BIT;
                end
            end
            ST_STOP_BIT : begin
                if(phase_cntr_end) begin
                    state_reg <= ST_IDLE;
                end
            end
            default :  begin
                if(tx_vld_reg) begin
                    state_reg <= ST_START_BIT;
                end
            end
        endcase
    end
end

always @(posedge clk) begin
    if(~rstn) begin
        phase_cntr_reg <= 10'd0;
    end
    else if(phase_cntr_end) begin
        phase_cntr_reg <= 10'd0;
    end
    else if(state_reg == ST_IDLE) begin
        phase_cntr_reg <= 10'd0;
    end
    else begin
        phase_cntr_reg <= phase_cntr_reg + 10'd1;
    end
end

always @(posedge clk) begin
    if(~rstn) begin
        bit_cntr_reg <= 3'd0;
    end
    else if( (state_reg==ST_DAT)&phase_cntr_end ) begin
        bit_cntr_reg <= bit_cntr_reg + 3'd1;
    end
end

// bit shift (lsb fisrt)
reg [7:0]       dat_shift_reg;
always @(posedge clk) begin
    if(~rstn) begin
        dat_shift_reg <= 8'h00;
    end 
    else if( (state_reg==ST_DAT)&phase_cntr_end ) begin
        dat_shift_reg <= {1'b0, dat_shift_reg[7:1]};
    end
    else if(tx_vld_reg) begin
        dat_shift_reg <= tx_dat_reg;
    end
end

// output
reg             uart_tx_reg;
assign  o_uart_tx = uart_tx_reg;
always @(posedge clk) begin
    if(~rstn) begin
        uart_tx_reg <= 1'b1;
    end
    else begin
        case (state_reg)
            ST_START_BIT: uart_tx_reg <= 1'b0;
            ST_DAT      : uart_tx_reg <= dat_shift_reg[0];
            default     : uart_tx_reg <= 1'b1;
        endcase
    end
end

// busy out
reg             busy_reg;
assign o_busy = busy_reg;
always @(posedge clk) begin
    if(~rstn) begin
        busy_reg <= 1'b0;
    end
    else begin
        busy_reg <= ~(state_reg==ST_IDLE);
    end
end

endmodule : uart_tx


module uart_rx #(
    parameter P_BAUD_RATE = 115200
)(
    // system
    input               clk,
    input               rstn,
    // uart IO
    input               i_uart_rx,
    // rx I/F
    output              o_vld,
    output  [7:0]       o_dat,
    output              o_busy,
    output              o_stpbt_err
);

// sync reg
(* ASYNC_REG = "TRUE" *)reg [2:0]   uart_rx_dff_reg;
wire uart_rx_we = uart_rx_dff_reg[2:1]==2'b10;
always @(posedge clk) begin
    if(~rstn) begin
        uart_rx_dff_reg <= 3'b000;
    end 
    else begin
        uart_rx_dff_reg <= {uart_rx_dff_reg[1:0], i_uart_rx};
    end
end

// state
typedef enum logic[1:0]{
    ST_IDLE,
    ST_START_BIT,
    ST_DAT,
    ST_STOP_BIT
} ST_UART_RX;
ST_UART_RX      state_reg;
reg [2:0]       bit_cntr_reg;
reg [9:0]       phase_cntr_reg;
wire[9:0]       phase_limit = baud_cntr_limit_100m(P_BAUD_RATE);
wire            phase_cntr_end  = phase_cntr_reg == phase_limit;
wire            phase_cntr_half = phase_cntr_reg == {1'b0, phase_limit[9:1]};

always @(posedge clk) begin
    if(~rstn) begin
        state_reg <= ST_IDLE;
    end
    else begin
        case (state_reg)
            ST_START_BIT : begin
                if(phase_cntr_end) begin
                    state_reg <= ST_DAT;
                end
            end
            ST_DAT : begin
                if(phase_cntr_end&(&bit_cntr_reg)) begin
                    state_reg <= ST_STOP_BIT;
                end
            end
            ST_STOP_BIT : begin
                if(phase_cntr_half) begin   // start bit取りこぼしがないよう半周期余裕をもつ
                    state_reg <= ST_IDLE;
                end
            end
            default : begin                 // ST_IDLE
                if(uart_rx_we) begin
                    state_reg <= ST_START_BIT;
                end
            end
        endcase
    end
end

always @(posedge clk) begin
    if(~rstn) begin
        phase_cntr_reg <= 10'd0;
    end
    else if(phase_cntr_end) begin
        phase_cntr_reg <= 10'd0;
    end
    else if(state_reg == ST_IDLE) begin
        phase_cntr_reg <= 10'd0;
    end
    else begin
        phase_cntr_reg <= phase_cntr_reg + 10'd1;
    end
end

always @(posedge clk) begin
    if(~rstn) begin
        bit_cntr_reg <= 3'd0;
    end
    else if( (state_reg==ST_DAT)&phase_cntr_end ) begin
        bit_cntr_reg <= bit_cntr_reg + 3'd1;
    end
end

// bit shift (lsb fisrt)
reg [7:0]       dat_shift_reg;
assign o_dat =  dat_shift_reg;
always @(posedge clk) begin
    if(~rstn) begin
        dat_shift_reg <= 8'h00;
    end 
    else if( (state_reg==ST_DAT)&phase_cntr_half ) begin
        dat_shift_reg <= {uart_rx_dff_reg[1], dat_shift_reg[7:1]};
    end
end

// valid out
reg             rx_vld_reg;
assign o_vld = rx_vld_reg;
always @(posedge clk) begin
    if(~rstn) begin
        rx_vld_reg <= 1'b0;
    end
    else if( (state_reg==ST_STOP_BIT)&phase_cntr_half ) begin
        rx_vld_reg <= 1'b1;
    end
    else begin
        rx_vld_reg <= 1'b0;
    end
end

// error out
reg             rx_stpbt_err_reg;
assign o_stpbt_err = rx_stpbt_err_reg;
always @(posedge clk) begin
    if(~rstn) begin
        rx_stpbt_err_reg <= 1'b0;
    end
    else if( (state_reg==ST_STOP_BIT)&phase_cntr_half ) begin
        rx_stpbt_err_reg <= ~uart_rx_dff_reg[1];
    end
end

// busy out
reg             busy_reg;
assign o_busy = busy_reg;
always @(posedge clk) begin
    if(~rstn) begin
        busy_reg <= 1'b0;
    end
    else begin
        busy_reg <= ~(state_reg==ST_IDLE);
    end
end

endmodule : uart_rx
