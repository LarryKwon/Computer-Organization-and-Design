module MicroCode #(
	parameter IWIDTH = 26, // control_signal 자리수
	parameter NDEPTH = 256, // control_signal의 가짓수
	parameter AWIDTH = 8 // control_signal의 가짓수를 나타낼 수 있는 index 자리수
) (	
    input wire RSTn,
    input wire[4:0] inst,
    input wire[2:0] stage,
    output wire [IWIDTH-1:0] control_signal // 26자리 배출
);
	//Declare the microcode that will store the control signal
    reg [IWIDTH -1:0] MC [NDEPTH-1:0];

	//Define asynchronous read
    reg [AWIDTH-1:0] index;
    always@(*) begin
        index = {inst[4:0],stage[2:0]};    
    end
	assign control_signal = MC[index];

    initial begin
        //표 작성
        
        //add
        MC[0] <=
        MC[1] <=
        MC[2] <=
        MC[3] <=
        MC[4] <=
        MC[5] <=
        MC[6] <=
        MC[7] <=
        MC[8] <=
        MC[9] <=
        MC[10] <=
        MC[11] <=
        MC[12] <=
        MC[13] <=
        MC[14] <=
        MC[15] <=
        MC[16] <=
        MC[17] <=
        MC[18] <=
        MC[19] <=
        MC[20] <=
        MC[21] <=
        MC[22] <=
        MC[23] <=
        MC[24] <=
        MC[25] <=
        MC[26] <=
        MC[27] <=
        MC[28] <=
        MC[29] <=
        MC[30] <=
        MC[31] <=
        MC[32] <=
        MC[33] <=
        MC[34] <=
        MC[35] <=
        MC[37] <=
        MC[38] <=
        MC[39] <=
        MC[40] <=
        MC[41] <=
        MC[42] <=
        MC[43] <=
        MC[44] <=
        MC[45] <=
        MC[46] <=
        MC[47] <=
        MC[48] <=
        MC[49] <=
        MC[50] <=
        MC[51] <=
        MC[52] <=
        MC[53] <=
        MC[54] <=
        MC[55] <=
        MC[56] <=
        MC[57] <=
        MC[58] <=
        MC[59] <=
        MC[60] <=
        MC[61] <=
        MC[62] <=
        MC[63] <=
        MC[64] <=
        MC[65] <=
        MC[66] <=
        MC[67] <=
        MC[68] <=
        MC[69] <=
        MC[70] <=
        MC[71] <=
        MC[72] <=
        MC[73] <=
        MC[74] <=
        MC[75] <=
        MC[76] <=
        MC[77] <=
        MC[78] <=
        MC[79] <=
    end

endmodule