module baud_gen #(
    parameter FREQ=100000000,
    parameter BAUD_RATE = 9600,
    parameter OVERSAMPLE = 16
) (
    input clk,
    input rst,
    output reg baud
);

localparam divisor = FREQ/(BAUD_RATE*OVERSAMPLE);

localparam counter_width = $clog2(divisor);

reg [counter_width-1:0] counter;

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        counter <= 0;
        baud <= 0;
    end else begin
        baud <= 1'b0;

        if(counter == divisor-1) begin
            counter <= 0;
            baud <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
        end
    end
end
    
endmodule
