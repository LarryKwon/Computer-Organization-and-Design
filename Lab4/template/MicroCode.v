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

        //R-type
        //add
        MC[8'b00000000] <= // add IF
        MC[8'b00000001] <= // add ID
        MC[8'b00000010] <= // add EX
        MC[8'b00000100] <= // add WB

        //sub
        MC[8'b00001 000] <= // sub IF
        MC[8'b00001 001] <= // sub ID
        MC[8'b00001 010] <= // sub EX
        MC[8'b00001 100] <= // sub WB

        //slt
        MC[8'b00010 000] <= // slt IF
        MC[8'b00010 001] <= // slt ID
        MC[8'b00010 010] <= // slt EX
        MC[8'b00010 100] <= // slt WB

        //sltu
        MC[8'b00011 000] <= // slt IF
        MC[8'b00011 001] <= // slt ID
        MC[8'b00011 010] <= // slt EX
        MC[8'b00011 100] <= // slt WB

        //xor
        MC[8'b00100 000] <= // xor IF 
        MC[8'b00100 001] <= // xor ID
        MC[8'b00100 010] <= // xor EX
        MC[8'b00100 100] <= // xor WB

        // or
        MC[8'b00101 000] <= // or IF
        MC[8'b00101 001] <= // or ID
        MC[8'b00101 010] <= // or EX
        MC[8'b00101 100] <= // or WB

        //and
        MC[8'b00110 000] <= // and IF
        MC[8'b00110 001] <= // and ID
        MC[8'b00110 010] <= // and EX
        MC[8'b00110 100] <= // and WB

        //sll
        MC[8'b00111 000] <= // sll IF
        MC[8'b00111 001] <= // sll ID
        MC[8'b00111 010] <= // sll EX
        MC[8'b00111 100] <= // sll WB

        //srl
        MC[8'b01000 000] <= // srl IF
        MC[8'b01000 001] <= // srl ID
        MC[8'b01000 010] <= // srl EX
        MC[8'b01000 100] <= // srl WB

        //sra
        MC[8'b01001 000] <= // sra IF
        MC[8'b01001 001] <= // sra ID
        MC[8'b01001 010] <= // sra EX
        MC[8'b01001 100] <= // sra WB

        //I-type
        //add
        MC[8'b01010 000] <= // add IF
        MC[8'b01010 001] <= // add ID
        MC[8'b01010 010] <= // add EX
        MC[8'b01010 100] <= // add WB

        //sub
        MC[8'b01011 000] <= // sub IF
        MC[8'b01011 001] <= // sub ID
        MC[8'b01011 010] <= // sub EX
        MC[8'b01011 100] <= // sub WB

        //slt
        MC[8'b01100 000] <= // slt IF
        MC[8'b01100 001] <= // slt ID
        MC[8'b01100 010] <= // slt EX
        MC[8'b01100 100] <= // slt WB

        //sltu
        MC[8'b01101 000] <= // sltu IF
        MC[8'b01101 001] <= // sltu ID
        MC[8'b01101 010] <= // sltu EX
        MC[8'b01101 100] <= // sltu WB

        //xor
        MC[8'b01110 000] <= // xor IF
        MC[8'b01110 001] <= // xor ID
        MC[8'b01110 010] <= // xor EX
        MC[8'b01110 100] <= // xor WB

        //or
        MC[8'b01111 000] <= // or IF
        MC[8'b01111 001] <= // or ID
        MC[8'b01111 010] <= // or EX
        MC[8'b01111 100] <= // or WB

        //and
        MC[8'b10000 000] <= // and IF
        MC[8'b10000 001] <= // and ID
        MC[8'b10000 010] <= // and EX
        MC[8'b10000 100] <= // and WB

        //sll
        MC[8'b10001 000] <= // sll IF
        MC[8'b10001 001] <= // sll ID
        MC[8'b10001 010] <= // sll EX
        MC[8'b10001 100] <= // sll WB

        //srl
        MC[8'b10010 000] <= // srl IF
        MC[8'b10010 001] <= // srl ID
        MC[8'b10010 010] <= // srl EX
        MC[8'b10010 100] <= // srl WB

        //sra
        MC[8'b10011 000] <= // sra IF
        MC[8'b10011 001] <= // sra ID
        MC[8'b10011 010] <= // sra EX
        MC[8'b10011 100] <= // sra WB

        //L-type
        //LW
        MC[8'10100 000] <= // LW IF
        MC[8'10100 001] <= // LW ID
        MC[8'10100 010] <= // LW EX
        MC[8'10100 011] <= // LW MEM
        MC[8'10100 100] <= // LW WB

        //S-type
        //SW
        MC[8'b10101 000] <= // SW IF
        MC[8'b10101 001] <= // SW ID
        MC[8'b10101 010] <= // SW EX
        MC[8'b10101 011] <= // SW MEM
        
        //JALR
        MC[8'b10110 000] <= // JALR IF
        MC[8'b10110 001] <= // JALR ID
        MC[8'b10110 010] <= // JALR EX
        MC[8'b10110 100] <= // JALR WB
        
        //JAL
        MC[8'b10111 000] <= // JALR IF
        MC[8'b10111 010] <= // JALR EX
        MC[8'b10111 100] <= // JALR WB
        
        //B-type
        //BEQ, BNE, BLT, BGE
        MC[8'b11000 000] <= // BXX IF
        MC[8'b11000 001] <= // BXX ID
        MC[8'b11000 010] <= // BXX EX

        //BLTU,BGEU
        MC[8'b11001 000] <= // BXXU IF
        MC[8'b11001 001] <= // BXXU ID
        MC[8'b11001 010] <= // BXXU EX

        //LUI
        MC[8'b11010 000] <= // LUI IF
        MC[8'b11010 100] <= // LUI WB

        //AUIPC
        MC[8'b11011 000] <= // AUIPC IF
        MC[8'b10011 010] <= // AUIPC EX
        MC[8'b10011 100] <= // AUIPC WB
    end

endmodule