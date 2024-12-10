// This is modelled after 61c's branch comparator
// Takes in BrUN, Amux and BMUX data, and outputs control logic for if data values are equal or less than
module BRANCH_COMP(
    input branch_unsigned, //should be 1 bit
    input [31:0] amux_output,
    input [31:0] bmux_output,
    output Equality,
    output LessThan
);

    reg equal, lessthan;

    assign Equality = equal;
    assign LessThan = lessthan;


    always @(*) begin
        equal = (amux_output == bmux_output);

        if (branch_unsigned) begin
            lessthan = (amux_output < bmux_output);
        end
        else begin
            lessthan = ($signed(amux_output) < $signed(bmux_output));
        end
    end
endmodule
