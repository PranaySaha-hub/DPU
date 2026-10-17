`timescale 1ns / 1ps
module SequenceCounter_tb;
    reg clk = 0, rst = 1, x = 0;
    wire z;
    integer i, errors = 0;

    reg [0:18] X = 19'b0010100100010111010;   // input from the question
    reg [0:18] Y = 19'b0001101011101100100;   // expected output

    SequenceChecker dut (.clk(clk), .rst(rst), .num(x), .detect(z));

    always #5 clk = ~clk;

    initial begin
        @(negedge clk); @(negedge clk);
        rst = 0;

        for (i = 0; i < 19; i = i + 1) begin
            x = X[i];
            #1;                                   // let the output settle
            if (z !== Y[i]) begin
                $display("FAIL at bit %0d: expected %b, got %b", i, Y[i], z);
                errors = errors + 1;
            end
            @(negedge clk);
        end

        if (errors == 0) $display("PASS");
        else $display("FAIL");
        $finish;
    end
endmodule