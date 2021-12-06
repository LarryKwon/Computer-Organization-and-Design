`timescale 1ns / 100ps

module ALU(A,B,OP,C,Cout);

	input [15:0]A;
	input [15:0]B;
	input [3:0]OP;
	output [15:0]C;
	output Cout;

	//TODO
	reg [15:0] ALU_RESULT;

	assign C = ALU_RESULT;


	reg[16:0] tmp_for_c1;
	reg[15:0] tmp_for_c2;
	
	reg[16:0] extend_A;
	reg[16:0] extend_B;

	assign Cout = (tmp_for_c1[16]!=tmp_for_c2[15]);

	always @(*)
	begin
		extend_A = A;
		extend_B = B;
		$display("ex_A : %b", extend_A);
		$display("ex_B : %b", extend_B);

		tmp_for_c1 = extend_A + extend_B;
		tmp_for_c2 = A[14:0] + B[14:0];
		$display("temp_for_c1 : %b", tmp_for_c1);
		$display("temp_for_c2 : %b", tmp_for_c2);
		case(OP)
			4'b0000: ALU_RESULT = A+B;
			4'b0001: ALU_RESULT = A-B;
			4'b0010: ALU_RESULT = A&B;
			4'b0011: ALU_RESULT = A|B;
			4'b0100: ALU_RESULT = ~(A&B);
			4'b0101: ALU_RESULT = ~(A|B);
			4'b0110: ALU_RESULT = A^B;
			4'b0111: ALU_RESULT = ~(A^B);
			4'b1000: ALU_RESULT = A;
			4'b1001: ALU_RESULT = ~A;
			4'b1010: ALU_RESULT = A>>1;
			4'b1011: ALU_RESULT = $signed(A)>>>1;
			4'b1100: ALU_RESULT = {A[0],A[15:1]};
			4'b1101: ALU_RESULT = A << 1;
			4'b1110: ALU_RESULT = $signed(A) <<< 1;
			4'b1111: ALU_RESULT = {A[14:0],A[15]};
			default: ALU_RESULT = A+B;
		endcase
	end
endmodule
