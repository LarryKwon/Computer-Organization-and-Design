module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN, //if RSTn == 1 -> CSN  = 0 / if RSTn == 0 -> CSN = 1 
	input wire [31:0] I_MEM_DI,//input from IM, the instruction
	output reg [11:0] I_MEM_ADDR,//in byte address to access instruction

	//D-Memory Signals
	output wire D_MEM_CSN, // if RSTn == 1 -> CSN  = 0 / if RSTn == 0 -> CSN = 1
	input wire [31:0] D_MEM_DI,// output from data memeory. the data what we read
	output wire [31:0] D_MEM_DOUT, // the date that we write on addr
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN, // if we want to execute the instruction that store data to memory, we make WEN = 0
	output wire [3:0] D_MEM_BE, // // 바이트 단위를 조정하기 위해 사용, byte enable 값으로 data를 읽거나 할 때(SB, SH, SW, LB, LH, LW 를 할 때 필요)

	//RegFile Signals
	output wire RF_WE, //register에 값을 저장하려고 할 때, 값이 1이 되어야함
	output wire [4:0] RF_RA1, // source register 1의 number를 만들어야 함
	output wire [4:0] RF_RA2, // source register 2의 number를 만들어야 함
	output wire [4:0] RF_WA1, // write register 1의 number를 만들어야 함
	input wire [31:0] RF_RD1, // source register 1로 부터 읽을 값
	input wire [31:0] RF_RD2, // source register 2로 부터 읽을 값
	output wire [31:0] RF_WD, // register file에 넣을 data
	output wire HALT,                   // if set, terminate program
	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT,      // equal RF_WD this port is used for test

	);

	//connect to regfile
	assign RF_RA1 = I_MEM_DI[19:15];
	assign RF_RA2 = I_MEM_DI[24:20];
	assign RF_WA1 = I_MEM_DI[11:7];

	//connect CSNs of I-Mem, D-Mem
	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;

	//ImmGen
	reg[31:0] imm;

	//control unit
	wire is_sign; // control_unit to alu_unit, branch_comp
	wire imm_control; // control_unit to ImmGen
	wire ASel; // control_unit to alu_unit
	wire BSel; // control_unit to alu_unit
	wire[4:0] alu_control; // control_unit to alu_unit
	wire[2:0] wb_control; // for pcSel, from control_unit


	//alu unit
	reg[31:0] alu_result;

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

	//port instantiation of control_unit
	ControlUnit control_unit(
		.RSTn			(RSTn),
		.I_MEM_DI		(I_MEM_DI),
		.BrEq			(BrEq),		
		.BrLt			(BrLt),
		.imm_control	(imm_control),
		.RF_WE			(RF_WE),
		.D_MEM_WEN		(D_MEM_WEN),
		.D_MEM_BE		(D_MEM_BE),
		.is_sign		(is_sign),
		.BSel			(BSel),
		.ASel			(ASel),
		.alu_control	(alu_control),
		.wb_control		(wb_control)
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

	assign OUTPUT_PORT = RF_WD;

	reg [11:0] pc;
	initial begin
		NUM_INST <= 0;
		pc <= 0;
	end

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (RSTn) NUM_INST <= NUM_INST + 1;
	end

	// TODO: implement


	reg[6:0] opcode;
	reg[2:0] func;

	assign opcode = I_MEM_DI[6:0];
	assign func = I_MEM_DI[14:12];

	always@(*) begin
		I_MEM_ADDR = pc & 12'hFFF;
	end

endmodule //