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
	
	reg Overflow;
	assign Cout = Overflow;

	initial begin
		Overflow = (tmp_for_c1[16]!=tmp_for_c2[15]);
	end

	always @(*)
	begin
		extend_A = A;
		extend_B = B;
		tmp_for_c1 = extend_A + extend_B;
		tmp_for_c2 = A[14:0] + B[14:0];

		case(OP)
			4'b0000: 
				begin
					ALU_RESULT = A+B;
					Overflow = (tmp_for_c1[16]!=tmp_for_c2[15]);
				end

			4'b0001: 
				begin
					ALU_RESULT = A-B;
					Overflow = (tmp_for_c1[16]!=tmp_for_c2[15]);
				end

			4'b0010: begin
					ALU_RESULT = A&B;
					Overflow = 0;
				end

			4'b0011: 
				begin
					ALU_RESULT = A|B;
					Overflow = 0;
				end

			4'b0100: 
				begin
					ALU_RESULT = ~(A&B);
					Overflow = 0;
				end

			4'b0101: 
				begin
					ALU_RESULT = ~(A|B);
					Overflow = 0;
				end

			4'b0110: 
				begin
					ALU_RESULT = A^B;
					Overflow = 0;
				end

			4'b0111: 
				begin
					ALU_RESULT = ~(A^B);
					Overflow = 0;
				end

			4'b1000: 
				begin
					ALU_RESULT = A;
					Overflow  = 0;
				end

			4'b1001: 
				begin
					ALU_RESULT = ~A;
					Overflow = 0;
				end

			4'b1010: 
				begin
					ALU_RESULT = A>>1;
					Overflow = 0;
				end

			4'b1011: 
				begin
					ALU_RESULT = $signed(A)>>>1;
					Overflow = 0;
				end

			4'b1100: 
				begin
					ALU_RESULT = {A[0],A[15:1]};
					Overflow = 0;
				end

			4'b1101: 
				begin
					ALU_RESULT = A << 1;
					Overflow = 0;
				end

			4'b1110: 
				begin
					ALU_RESULT = $signed(A) <<< 1;
					Overflow = 0;
				end
			4'b1111: 
				begin
					ALU_RESULT = {A[14:0],A[15]};
					Overflow = 0;
				end
			default: ALU_RESULT = A+B;
		endcase
	end
endmodule
