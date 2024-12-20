module reg_file (
    input clk,
    input we,
    input [4:0] ra1, ra2, wa,
    input [31:0] wd,
    output [31:0] rd1, rd2
);
    parameter DEPTH = 32;
    reg [31:0] mem [0:31];

	reg [31:0] rd1_reg;
	reg [31:0] rd2_reg;

	assign rd1 = rd1_reg;
	assign rd2 = rd2_reg;

	always @(posedge clk) begin
	// assign 0 if writing to x0
        if (we) begin
			if (wa != 0)
            	mem[wa] <= wd;
			mem[0] <= 0;
		end
    end

    always @(*) begin
		if (ra1 == 0)
        	rd1_reg = 0;
		else
        	rd1_reg = mem[ra1];

		if (ra2 == 0)
        	rd2_reg = 0;
		else
        	rd2_reg = mem[ra2];
    end
endmodule
