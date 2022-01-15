module MicroCode #(
	parameter IWIDTH = 28,
	parameter NDEPTH = 64,
	parameter AWIDTH = 6
) (	
    input wire RSTn,
    input wire[AWIDTH-1:0] index,
    output wire [IWIDTH-1:0] control_signal;
);
	//Declare the microcode that will store the control signal
    reg [IWIDTH -1:0] MC [NDEPTH-1:0];

	//Define asynchronous read
	assign control_signal = MC[index];

    initial begin
        
    end

endmodule