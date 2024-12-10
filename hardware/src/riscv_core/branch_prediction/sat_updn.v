/*
A saturating incrementer/decrementer.
Adds +/-1 to the input with saturation to prevent overflow.
*/

module sat_updn #(
    parameter WIDTH=2
) (
    input [WIDTH-1:0] in,
    input up,
    input dn,

    output [WIDTH-1:0] out
);

    localparam [1:0] 
        StronglyNotTaken = 2'b00, 
        WeaklyNotTaken   = 2'b01, 
        WeaklyTaken      = 2'b10, 
        StronglyTaken    = 2'b11;

    reg [WIDTH-1:0] out_reg; 
    assign out = out_reg;

    always @(*) begin
        out_reg = in;
        case (in)
            StronglyNotTaken: begin
                if (up) out_reg = WeaklyNotTaken;
                //if down, stay here
            end
            WeaklyNotTaken: begin
                if (up) out_reg = WeaklyTaken;
                else if (dn) out_reg = StronglyNotTaken;
            end
            WeaklyTaken: begin
                if (up) out_reg = StronglyTaken;
                else if (dn) out_reg = WeaklyNotTaken;
            end
            StronglyTaken: begin
                //if up, stay here
                if (dn) out_reg = WeaklyTaken;
            end
        endcase
    end

endmodule