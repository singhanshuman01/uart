module rx (
    input clk,
    input rst,

    input rx,
    input baud,

    input full,
    output reg [7:0] wdata,
    output reg wen
);

localparam IDLE = 2'b00,
           START = 2'b01,
           RECEIVE = 2'b10,
           STOP = 2'b11;

reg [1:0] state, next_state;

reg [7:0] shift_reg;

reg [2:0] bit_counter;
reg [3:0] baud_counter;


//state transition
always @(posedge clk or negedge rst) begin
    if(!rst) state <= IDLE;
    else if(baud) state <= next_state;
end

//state transition logic
always @(*) begin
    case (state)
        IDLE: next_state = (!rx) ? START:IDLE;
        START: next_state = (baud_counter==7)? RECEIVE:START;
        RECEIVE: next_state = (bit_counter==3'b111) ? STOP:RECEIVE;
        STOP: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end


//shift register logic (SIPO)
always @(posedge clk or negedge rst) begin
    if(!rst) shift_reg <= 0;
    else begin
        if(state == RECEIVE && baud_counter==15) shift_reg <= {rx, shift_reg[7:1]};
        else shift_reg <= shift_reg;
    end
end

//output logic
always @(*) begin
    case (state)
        IDLE: {wdata, wen} = 0;
        START: {wdata, wen} = 0;
        RECEIVE: {wdata, wen} = 0;
        STOP: if(!full && baud) {wdata, wen} = {shift_reg, 1'b1};
        default: {wdata, wen} = 0;
    endcase
end

//bit and baud counter logic
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        bit_counter <= 0;
        baud_counter <= 0;
    end else if(baud) begin
        if(state==START && baud_counter==7) baud_counter <= 0;
        else baud_counter <= baud_counter + 1'b1;

        if(state == RECEIVE && baud_counter==15) bit_counter <= bit_counter+1'b1;
    end
end

endmodule