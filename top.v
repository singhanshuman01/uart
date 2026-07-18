module top #(
    parameter integer FREQ = 100_000_000,
    parameter integer BAUD_RATE = 9600
) (
    input clk,
    input rst,

    input rx,
    output tx,

    input tx_write,
    input [7:0] tx_data,

    input rx_read,
    output [7:0] rx_data,

    output tx_full,
    output tx_empty,
    output rx_full,
    output rx_empty
);

wire tx_baud, rx_baud;
wire tx_ren, rx_wen;
wire [7:0] tx_rdata, rx_wdata;

baud_gen #(
    .FREQ(FREQ), 
    .BAUD_RATE(BAUD_RATE), 
    .OVERSAMPLE(1)) bgen1 (
    .clk(clk),
    .rst(rst),
    .baud(tx_baud)
);

baud_gen #(
    .FREQ(FREQ), 
    .BAUD_RATE(BAUD_RATE), 
    .OVERSAMPLE(16)) bgen2 (
    .clk(clk),
    .rst(rst),
    .baud(rx_baud)
);

fifo #(
    .DEPTH(16)
    ) tx_fifo (
    .clk(clk),
    .rst(rst),

    .wen(tx_write),
    .wdata(tx_data),

    .ren(tx_ren),
    .rdata(tx_rdata),

    .full(tx_full),
    .empty(tx_empty)
);

tx tx1 (
    .clk(clk),
    .rst(rst),

    .baud(tx_baud),
    .fifo_empty(tx_empty),
    .data(tx_rdata),

    .ren(tx_ren),
    .tx(tx)
);

fifo #(
    .DEPTH(16)
    ) rx_fifo (
    .clk(clk),
    .rst(rst),

    .wen(rx_wen),
    .wdata(rx_wdata),

    .ren(rx_read),
    .rdata(rx_data),

    .full(rx_full),
    .empty(rx_empty)
);

rx rx1 (
    .clk(clk),
    .rst(rst),

    .rx(rx),
    .baud(rx_baud),

    .full(rx_full),
    .wdata(rx_wdata),
    .wen(rx_wen)
);

endmodule