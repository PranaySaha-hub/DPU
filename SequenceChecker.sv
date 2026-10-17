`timescale 1ns / 1ps
module SequenceChecker
( 
    input clk,
    input num,
    input rst,
    output reg detect
);

typedef enum logic [3:0] {
    S0, S1, S3,S4,S5,S6,S7,S8,S9,S10,S11,S12
} state_t;

state_t current_state, next_state;

always @(posedge clk) begin
    if (!rst)
    current_state <= next_state;
    else if (rst)
    current_state <= S0;
end

always_comb begin
    next_state = current_state;
    detect = 1'b0;
    case (current_state)
        S0: if(num) next_state=S9; else next_state=S1;
        S1 : if (num) next_state=S3; else next_state=S1;
        S3 : if (num) next_state=S4; else next_state=S6;
        S4 : if (num) next_state=S5; else next_state=S1;
        S5 : begin
            if (num) next_state=S0; else next_state=S1;
            detect = 1'b1;
        end
        S6: if(num) next_state=S8; else next_state=S7;
        S7: begin if(num) next_state=S3; else next_state=S1;
                detect=1'b1; end

        S8: begin if(num) next_state=S10; else next_state=S6;
        detect=1'b1; end

        S9: if(num) next_state=S9; else next_state=S1;
        S10: if(num) next_state=S11; else next_state=S10;
        S12: begin if(num) next_state=S3; else next_state=S1;
             detect=1'b1; end
    endcase 
end
endmodule
