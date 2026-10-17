module MsgReceiver (
    input  wire clk,
    input  wire rst,       // synchronous, active-high
    input  wire valid,     // a byte is present on data in this cycle
    input  wire [7:0] data,
    output wire done
);
    localparam [1:0] WAIT1 = 2'd0,   // searching for the first byte (bit 3 = 1)
                     GOT1  = 2'd1,   // first byte seen, waiting for the 2nd
                     GOT2  = 2'd2,   // second byte seen, waiting for the 3rd
                     DONE  = 2'd3;   // third byte just received

    reg [1:0] state, next_state;

    always @(posedge clk) begin
        if (rst) state <= WAIT1;
        else     state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            // DONE lasts one clock; a byte arriving then is treated like in WAIT1
            WAIT1, DONE: if (valid && data[3]) next_state = GOT1;
                         else                  next_state = WAIT1;
            GOT1:        if (valid) next_state = GOT2;
            GOT2:        if (valid) next_state = DONE;
            default:     next_state = WAIT1;
        endcase
    end

    assign done = (state == DONE);
endmodule