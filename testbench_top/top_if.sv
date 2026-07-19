interface top_if(input logic clock,rst);
    logic rx;
    logic tx;

    logic tx_write;
    logic [7:0] tx_data;

    logic rx_read;
    logic [7:0] rx_data;

    logic tx_full;
    logic tx_empty;
    logic rx_full;
    logic rx_empty;

endinterface