// MUX module
module MUX2(sel, in0, in1, out);
  input sel;
  input [31:0] in0, in1;
  output reg [31:0] out;
  
  always @(*) begin
	case(sel)
	  1'b0: out = in0;
	  1'b1: out = in1;
	  default: out = 0;
	endcase
  end
endmodule // TWO_INPUT_MUX

module MUX4(sel, in0, in1, in2, in3, out);
  input [1:0] sel;
  input [31:0] in0, in1, in2, in3;
  output reg [31:0] out;
  
  always @(*) begin
	case(sel)
	  2'b00: out = in0;
	  2'b01: out = in1;
	  2'b10: out = in2;
	  2'b11: out = in3;
	  default: out = 0;
	endcase
  end
endmodule // FOUR_INPUT_MUX

module MUX5 (sel, in0, in1, in2, in3, in4, out);
  input [2:0] sel;
  input [31:0] in0, in1, in2, in3, in4;
  output reg [31:0] out;
  
  always @(*) begin
	case(sel)
	  3'b000: out = in0;
	  3'b001: out = in1;
	  3'b010: out = in2;
	  3'b011: out = in3;
	  3'b100: out = in4;
	  default: out = 0;
	endcase
  end
endmodule // EIGHT_INPUT_MUX

module ADDER(in0, in1, out);
  input [31:0] in0, in1;
  output [31:0] out;
  
  assign out = in0 + in1;
endmodule // ADDER
