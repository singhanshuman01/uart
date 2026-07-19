`timescale 1ns/1ps

interface fifo_if(input logic clk);
    logic rst;
    logic wen;
    logic [7:0] wdata;
    logic ren;

    logic full;
    logic empty;

    logic [7:0] rdata;

    clocking sb @(posedge clk);
        input rdata;
        output ren;
        output wen;
    endclocking
endinterface //u_if

class transaction;
rand logic wen;
rand logic ren;
rand logic [7:0] wdata;
rand logic rst;

bit [7:0] rdata;
bit full;
bit empty;

constraint c_rst { rst dist {0:=1, 1:=19};}


endclass

class generator #(transaction);
// transaction tr;
mailbox #(transaction) gen2drv;
event drvdone;

function new(mailbox #(transaction) gen2drv, event drvdone);
    this.gen2drv = gen2drv;
    this.drvdone = drvdone;
endfunction

task run();
    forever begin
        transaction tr;
        tr = new();

        assert(tr.randomize());
        gen2drv.put(tr);

        wait(drvdone.triggered);
    end
endtask

endclass

class driver #(transaction);
virtual fifo_if fif;
mailbox #(transaction) gen2drv;
event drvdone;

function new(virtual fifo_if fif, mailbox #(transaction) gen2drv, event drvdone);
    this.fif = fif;
    this.gen2drv = gen2drv;
    this.drvdone = drvdone;
endfunction

task run();
    @(posedge fif.clk);
    forever begin        
        transaction tr;
        gen2drv.get(tr);

        fif.rst <= tr.rst;
        fif.wen <= tr.wen;
        fif.ren <= tr.ren;
        fif.wdata <= tr.wdata;

        @(posedge fif.clk);
        |->drvdone;
    end
endtask

endclass

class monitor #(transaction);
mailbox #(transaction) mon2scb;
virtual fifo_if fif;

function new(virtual fifo_if fif, mailbox #(transaction) mon2scb);
    this.fif = fif;
    this.mon2scb = mon2scb;
endfunction

task run();
    @(posedge fif.clk);
    forever begin
        transaction tr;
        tr = new();

        @(negedge clk);
        tr.wen <= fif.wen;
        tr.ren <= fif.ren;
        tr.wdata <= fif.wdata;
        tr.rst <= fif.rst;

        tr.rdata <= fif.rdata;
        tr.full <= fif.full;
        tr.empty <= fif.empty;

        mon2scb.put(tr);

    end
endtask


endclass


class scoreboard #(transaction);

mailbox #(transaction) mon2scb;

function new(mailbox #(transaction) mon2scb);
    this.mon2scb = mon2scb;
endfunction


int pass = 0;
int fail = 0;


task run();
    bit [7:0] d_queue[$];
    bit [7:0] exp_data;
    int depth=16;
    forever begin
        transaction tr;
        mon2scb.get(tr);
        if(tr.wen && !tr.full) begin
            d_queue.push_back(tr.wdata);
            $display("Added %0h to queue", tr.wdata);
        end

        if(tr.ren && !tr.empty) begin
            if(d_queue.size()==0) begin
                fail++;
                $display("FAILED: DUT allowed read even though queue is empty!");
            end else begin
                exp_data = queue.pop_front();

                if(tx.rdata === exp_data) begin
                    pass++;
                    $display("PASSED: read data matched queue data");
                end else begin
                    fail++;
                    $display("FAILED: read data didn't match queue data");
                end
            end
        end

        if(queue.size()==0 && !tr.empty) begin
            fail++;
            $display("FAILED: Queue empty but DUT empty not HIGH");
        end

        if(queue.size()==depth && !tr.full) begin
            fail++;
            $display("FAILED: Queue full but DUT full not HIGH");
        end
    end
endtask

endclass


class env;
generator gen;
monitor mon;
driver drv;
scoreboard scb;

mailbox #(transaction) gen2drv;
mailbox #(transaction) mon2scb;

virtual fifo_if fif;

event drvdone;

function new(virtual fifo_if fif);
    this.fif = fif;
    gen2drv = new();
    mon2scb = new();
    gen = new(gen2drv, drvdone);
    scb = new(mon2scb);
    drv = new(fif, gen2drv, drvdone);
    mon = new(fif, mon2scb);
endfunction

task run();
    fork
        gen.run();
        drv.run();
        mon.run();
        scb.run();
    join
endtask

endclass

class test;

env e;
virtual fifo_if fif;

function new(virtual fifo_if fif);
    this.fif = fif;
    e = new(fif);
endfunction

task run();
    e.run();
endtask
endclass

module tb;
test t0;

logic clk;

always #10 clk = ~clk;

fifo_if fif(clk);

fifo f1(
    .clk(fif.clk),
    .rst(fif.rst),

    .wen(fif.wen),
    .wdata(fif.wdata),

    .ren(fif.ren),
    .rdata(fif.rdata),

    .full(fif.full),
    .empty(fif.empty)
);

initial begin
    {clk, fif.rst} = 0;
    #30 fif.rst = 1;


    t0 = new(fif);

    t0.run();

    #100 $finish;
end

initial begin
    $dumpfile("fifo.vcd");
    $dumpvars;
end

endmodule