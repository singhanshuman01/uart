module fifo #(
    parameter DEPTH = 16
) (
    input clk,
    input rst,

    input wen,
    input [7:0] wdata,

    input ren,
    output reg [7:0] rdata,

    output full,
    output empty
);

reg [$clog2(DEPTH)-1:0] rptr, wptr;
reg [7:0] mem [0:DEPTH-1];

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        rdata <= 0;
        rptr <= 0;
        wptr <= 0;
    end else begin
        if(wen && !full) begin 
            mem[wptr] <= wdata;
            wptr <= wptr + 1'b1;
        end
        if(ren  && !empty) begin
            rdata <= mem[rptr];
            rptr <= rptr + 1'b1;
        end
    end
end

assign full = (wptr+1'b1)==rptr;
assign empty = rptr == wptr;

endmodule
