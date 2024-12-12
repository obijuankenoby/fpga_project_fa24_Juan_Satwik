module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [WIDTH-1:0] dout,
    output empty
);

    reg [WIDTH-1:0] circular_buff [0:DEPTH-1];
    reg [POINTER_WIDTH:0] wr_ptr, rd_ptr;
    reg [WIDTH-1:0]dout_reg;

    assign dout = dout_reg;


    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            dout_reg <= 0;
        end
        else begin
            if (wr_en && !full) begin
                circular_buff[wr_ptr[POINTER_WIDTH-1:0]] <= din;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en && !empty) begin
                dout_reg <= circular_buff[rd_ptr[POINTER_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end
    assign empty = (wr_ptr == rd_ptr);
    assign full = ((wr_ptr[POINTER_WIDTH] != rd_ptr[POINTER_WIDTH]) && (wr_ptr[POINTER_WIDTH-1:0] == rd_ptr[POINTER_WIDTH-1:0]));

    // assert property (@(posedge clk) disable iff (rst) full |=> (wr_ptr == $past(wr_ptr)));
    // assert property (@(posedge clk) disable iff (rst) empty |=> (rd_ptr == $past(rd_ptr)));
    // assert property (@(posedge clk) rst |=> (wr_ptr == 0 && rd_ptr == 0 && !full));

endmodule
