module MEM_MASK(mem_mask_in, mem_mask_select, mem_mask_out, mem_mask_alu_out);
	input [31:0] mem_mask_in;
	input [2:0] mem_mask_select;
	input [31:0] mem_mask_alu_out;
	output reg [31:0] mem_mask_out;

	always @(*) begin
		if (mem_mask_alu_out[1:0] == 0) begin
			case(mem_mask_select)
				3'b000: mem_mask_out = mem_mask_in; // load word
				3'b001: mem_mask_out = {{16{1'b0}}, mem_mask_in[15:0]}; // lhu
				3'b010: mem_mask_out = {{16{mem_mask_in[15]}}, mem_mask_in[15:0]}; // lh
				3'b011: mem_mask_out = {{24{1'b0}}, mem_mask_in[7:0]}; // lbu
				3'b100: mem_mask_out = {{24{mem_mask_in[7]}}, mem_mask_in[7:0]}; // lb
			endcase
		end
		else if (mem_mask_alu_out[1:0] == 1) begin
			case(mem_mask_select)
				// not sure if LH can have offset of one
				3'b001: mem_mask_out = {{16{1'b0}}, mem_mask_in[23:8]}; // lhu
				3'b010: mem_mask_out = {{16{mem_mask_in[23]}}, mem_mask_in[23:8]}; // lh
				3'b011: mem_mask_out = {{24{1'b0}}, mem_mask_in[15:8]}; // lbu
				3'b100: mem_mask_out = {{24{mem_mask_in[15]}}, mem_mask_in[15:8]}; // lb
			endcase
		end
		else if (mem_mask_alu_out[1:0] == 2) begin
			case(mem_mask_select)
				3'b001: mem_mask_out = {{16{1'b0}}, mem_mask_in[31:16]}; // lhu
				3'b010: mem_mask_out = {{16{mem_mask_in[31]}}, mem_mask_in[31:16]}; // lh
				3'b011: mem_mask_out = {{24{1'b0}}, mem_mask_in[23:16]}; // lbu
				3'b100: mem_mask_out = {{24{mem_mask_in[23]}}, mem_mask_in[23:16]}; // lb
			endcase
		end
		else if (mem_mask_alu_out[1:0] == 3) begin
			case(mem_mask_select)
				3'b011: mem_mask_out = {{24{1'b0}}, mem_mask_in[31:24]}; // lbu
				3'b100: mem_mask_out = {{24{mem_mask_in[31]}}, mem_mask_in[31:24]}; // lb
			endcase
		end
	end
endmodule
