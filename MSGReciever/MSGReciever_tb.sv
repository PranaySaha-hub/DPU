`timescale 1ns / 1ps
module MSGReciever_tb;
    reg clk = 0, rst = 1, valid = 0;
    reg [7:0] data = 0;
    wire done;
    integer errors = 0;

    MsgReceiver dut (.clk(clk), .rst(rst), .valid(valid), .data(data), .done(done));
    always #5 clk = ~clk;

    task step(input v, input [7:0] d, input exp_done);
        begin
            valid = v; data = d;
            @(negedge clk);
            if (done !== exp_done) begin
                $display("FAIL @%0t: valid=%b data=%h, done=%b expected %b", $time, v, d, done, exp_done);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        @(negedge clk); @(negedge clk);
        rst = 0;

        // 1. invalid bytes before a message are discarded (bit 3 = 0)
        step(1, 8'h00, 0);
        step(1, 8'h07, 0);
        step(1, 8'h71, 0);

        // 2. one normal message: done right after the 3rd byte, for one clock
        step(1, 8'h08, 0);
        step(1, 8'h00, 0);
        step(1, 8'h00, 1);     // 3rd byte -> done
        step(0, 8'h00, 0);     // done is only one clock

        // 3. gaps between the valid bytes
        step(1, 8'h0C, 0);
        step(0, 8'h00, 0);
        step(0, 8'hFF, 0);     // garbage with valid=0 must be ignored
        step(1, 8'h01, 0);
        step(0, 8'h00, 0);
        step(1, 8'h02, 1);
        step(0, 8'h00, 0);

        // 4. 2nd and 3rd bytes may have bit 3 = 1
        step(1, 8'h08, 0);
        step(1, 8'h0F, 0);
        step(1, 8'h0F, 1);
        step(0, 8'h00, 0);

        // 5. consecutive messages: next first byte arrives right while done is high
        step(1, 8'h09, 0);
        step(1, 8'h11, 0);
        step(1, 8'h22, 1);     // done
        step(1, 8'h18, 0);     // first byte of the next message
        step(1, 8'h33, 0);
        step(1, 8'h44, 1);     // done again
        step(0, 8'h00, 0);

        // 6. after a message, bytes with bit 3 = 0 are discarded again
        step(1, 8'h00, 0);
        step(1, 8'h01, 0);
        step(1, 8'h08, 0);     // a new message starts
        step(1, 8'h00, 0);
        step(1, 8'h00, 1);
        step(0, 8'h00, 0);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule