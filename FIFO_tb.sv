`timescale 1ns / 1ps
module tb_simple_fifo;
    parameter DEPTH = 8;

    reg         clk = 0, rst_n = 0;
    reg         packet_valid = 0, packet_ready = 0;
    reg  [31:0] packet_in = 0;
    wire        packet_drop, empty, full, packet_out_valid;
    wire [31:0] packet_out;
    integer     i, errors = 0;

    packet_fifo #(.DATA_WIDTH(32), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .packet_valid(packet_valid), .packet_in(packet_in), .packet_drop(packet_drop),
        .packet_ready(packet_ready), .packet_out(packet_out),
        .packet_out_valid(packet_out_valid), .empty(empty), .full(full));

    always #5 clk = ~clk;

    // compare a flag with its expected value
    task check(input got, input exp, input [8*20-1:0] name);
        begin
            if (got !== exp) begin
                $display("FAIL: %0s = %b, expected %b", name, got, exp);
                errors = errors + 1;
            end
        end
    endtask

    // insert one packet (one clock)
    task push(input [31:0] d);
        begin
            packet_valid = 1; packet_in = d;
            @(negedge clk);
            packet_valid = 0;
        end
    endtask

    // remove one packet and check the data that comes out
    task pop(input [31:0] exp);
        begin
            packet_ready = 1;
            @(negedge clk);
            packet_ready = 0;
            if (packet_out !== exp) begin
                $display("FAIL: removed %h, expected %h", packet_out, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // reset
        @(negedge clk); @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        check(empty, 1, "empty after reset");
        check(full,  0, "full after reset");

        // 1. insert 3, remove 3 in the same order
        push(32'hA1); push(32'hA2); push(32'hA3);
        check(empty, 0, "empty with data");
        pop(32'hA1); pop(32'hA2); pop(32'hA3);
        check(empty, 1, "empty after popping");

        // 2. fill the FIFO
        for (i = 0; i < DEPTH; i = i + 1) push(32'h10 + i);
        check(full, 1, "full");

        // 3. one more packet is dropped (drop is high for one clock)
        push(32'hEE);
        check(packet_drop, 1, "drop after push");
        @(negedge clk);
        check(packet_drop, 0, "drop one cycle only");
        check(full, 1, "still full");

        // 4. remove everything, original packets only
        for (i = 0; i < DEPTH; i = i + 1) pop(32'h10 + i);
        check(empty, 1, "empty again");

        // 5. insert and remove in the same clock
        push(32'h51); push(32'h52);
        packet_valid = 1; packet_in = 32'h53; packet_ready = 1;   // both at once
        @(negedge clk);
        packet_valid = 0; packet_ready = 0;
        if (packet_out !== 32'h51) begin
            $display("FAIL: simultaneous op removed %h, expected 51", packet_out);
            errors = errors + 1;
        end
        pop(32'h52);
        pop(32'h53);                       // the packet inserted at the same time is kept
        check(empty, 1, "empty at end");

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule