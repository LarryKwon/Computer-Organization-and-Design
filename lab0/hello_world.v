`timescale 1ns/100ps
module counter(clock,reset,enable,out);
	input clock;
	input reset;
	input enable;
	output[0:3] out;
	reg[0:3] out;
	initial begin
	end
	always @(posedge clock) begin
		if(enable == 1'b1) begin
			if(reset == 1'b1)
				out <= 4'b0000;
			else begin
				out <= out+1;
			end
		end
	end
endmodule