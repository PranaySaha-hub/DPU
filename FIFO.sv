module packet_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire packet_valid,
    input  wire [DATA_WIDTH-1:0] packet_in,
    output reg packet_drop,
    input  wire packet_ready,
    output reg  [DATA_WIDTH-1:0] packet_out,
    output wire packet_out_valid,
    output wire empty,
    output wire full
);
    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [DATA_WIDTH-1:0] fifo [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) &&
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    wire do_read  = packet_ready && !empty;
    wire do_write = packet_valid && (!full || packet_ready);   // a simultaneous remove frees a slot
    reg out_valid_r;
    assign packet_out_valid = out_valid_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0; rd_ptr <= 0; packet_drop <= 1'b0; packet_out <= 0; out_valid_r <= 1'b0;
        end else begin
            if (packet_valid && full && !packet_ready) packet_drop <= 1'b1;
            else                                       packet_drop <= 1'b0;
            out_valid_r <= do_read;
            if (do_write) begin
                fifo[wr_ptr[ADDR_WIDTH-1:0]] <= packet_in;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (do_read) begin
                packet_out <= fifo[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr     <= rd_ptr + 1'b1;
            end
        end
    end
endmodule