`include "top.v"

class trans_top;

    logic rx;
    logic tx;

    logic tx_write;
    rand logic [7:0] tx_data;

    logic rx_read;
    logic [7:0] rx_data;

    logic tx_full;
    logic tx_empty;
    logic rx_full;
    logic rx_empty;
    
    function void print(string tag ="");
        $display ("Time = %0t :: [%s] || tx_write: %0b ___ tx_data: %0d || rx_read: %0b ____ rx_data: %0d ",
                    $time, tag, tx_write, tx_data, rx_read, rx_data );       
    endfunction
endclass : trans_top


class genrator;
    mailbox drv_mbx;
    event drv_done;
    int num = 20;

    task run();
        for (int i = 0; i<num; i++) begin
            trans_top item = new();
            assert(item.randomize());
            drv_mbx.put(item);
            @(drv_done);
        end 
    endtask
    


endclass : genrator