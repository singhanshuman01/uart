`timescale 1ns/1ps
module tb;
reg clk;
reg rst;
wire baud;

baud_gen b1(
    .clk(clk),
    .rst(rst),
    .baud(baud)
);

initial begin
    clk = 0;
    rst = 0;
    #20 rst = 1;

    #10000 $finish;
end

always #5 clk = ~clk;

initial begin
    $dumpfile("baud.vcd");
    $dumpvars;
end

endmodule
