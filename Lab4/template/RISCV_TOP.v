module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN, // RSTn == 1 -> CSN = 0, RSTn == 0 -> CSN = 1
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

	//D-Memory Signals
	output wire D_MEM_CSN, // RSTn == 1 -> CSN = 0, RSTn == 0 -> CSN = 1
	input wire [31:0] D_MEM_DI, // read data 
	output wire [31:0] D_MEM_DOUT, // write data
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN, // write시 WEN = 0
	output wire [3:0] D_MEM_BE, // byte enable 값

	//RegFile Signals
	output wire RF_WE, // register에 값을 쓸 때 1, 아니면 0
	output wire [4:0] RF_RA1, // register1의 넘버
	output wire [4:0] RF_RA2, // register2의 넘버
	output wire [4:0] RF_WA1, // write regiserdml 넘버
	input wire [31:0] RF_RD1, //  RA1로부터의 값
	input wire [31:0] RF_RD2, // RA2로부터의 값
	output wire [31:0] RF_WD, // register에 쓸 값
	output wire HALT, // terminate
	output reg [31:0] NUM_INST, // 몇 번째 inst인지, 끝날 때 1씩 올려야한다.
	output wire [31:0] OUTPUT_PORT // 
	);

	// TODO: implement multi-cycle CPU

	//connect to regfile
	assign RF_RA1 = I_MEM_DI[19:15];
	assign RF_RA2 = I_MEM_DI[24:20];
	assign RF_WA1 = I_MEM_DI[11:7];

	//connect CSNs of I-Mem, D-Mem
	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;

	//ImmGen
	wire[31:0] imm;

	//termination & output Port
	wire termination_flag = 0;
	reg termination_flag_reg;
	reg[6:0] opcode;
	reg HALT_reg;

	assign termination_flag = termination_flag_reg;
	assign HALT = HALT_reg;
	assign opcode = I_MEM_DI[6:0];

	//alu unit
	wire[31:0] alu_result;
	reg [11:0] pc;

	//BranchComp
	wire BrEq; // BranchComp to controlUnit
	wire BrLt; // BranchComp to controlUnit


	//port instantiation of ImmGen
	ImmGen imm_gen1(
		.RSTn			(RSTn),
		.imm_control	(imm_control),
		.I_MEM_DI		(I_MEM_DI),
		.imm			(imm)
	);

	//port instantiation of BranchComp
	BranchComp branch_comp(
		.RSTn 		(RSTn),
		.is_sign 	(is_sign),
		.RF_RD1  	(RF_RD1), // source register 1로 부터 읽을 값
		.RF_RD2  	(RF_RD2), // source register 2로 부터 읽을 값
   		.BrEq    	(BrEq),
    	.BrLt    	(BrLt)
	);	

	AluUnit alu_unit(
		 .RSTn			(RSTn),
		 .ASel			(ASel),
		 .BSel			(BSel),
		 .is_sign		(is_sign),
		 .alu_control	(alu_control),
		 .RF_RD1		(RF_RD1), // source register 1로 부터 읽을 값
		 .RF_RD2		(RF_RD2), // source register 2로 부터 읽을 값
		 .imm			(imm),
		 .pc			(pc),
		 .alu_result	(alu_result)
	);

	
endmodule //
