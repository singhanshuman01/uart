module tx (
    input clk,
    input rst,

    input baud,
    input fifo_empty,
    input [7:0] data,

    output reg ren,
    output reg tx
);

localparam IDLE = 2'b00,
           START = 2'b01,
           DATA = 2'b10,
           STOP = 2'b11;

reg [1:0] state, next_state;
reg [7:0] shift_reg;
reg [2:0] counter;

//state transition
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        state <= IDLE;
    end else if(baud) begin
        state <= next_state;
    end
end

//state change logic
always @(*) begin
    case (state)
        IDLE: next_state = (!fifo_empty) ? START:IDLE;
        START: next_state = DATA;
        DATA: next_state = (counter==3'b111) ? STOP:DATA;
        STOP: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

//counter logic
always @(posedge clk or negedge rst) begin
    if(!rst) counter <= 0;
    else if(baud) begin
        if(state==DATA) begin
            if(counter == 7) counter <= 0;
            else counter <= counter+1'b1;
        end else begin
            counter <= 0;
        end
    end
end

//shift logic
always @(posedge clk or negedge rst) begin
    if(!rst) shift_reg <= 1;
    else begin
        if(baud) begin
            if(state == IDLE && !fifo_empty) shift_reg <= data;
            else if(state == DATA) shift_reg <= shift_reg >> 1;
        end
    end
end

//output logic
always @(*) begin
    case (state)
        IDLE: begin
            tx = 1;
            if(baud && !fifo_empty) ren = 1;
            else ren = 0;
        end
        START: {tx, ren} = 2'b00;
        DATA: {tx, ren} = {shift_reg[0], 1'b0};
        STOP: {tx, ren} = 2'b10;
        default: {tx,ren} = 2'b10;
    endcase
end

    
endmodule