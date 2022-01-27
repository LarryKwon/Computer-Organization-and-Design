module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN,
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

	//D-Memory Signals
	output wire D_MEM_CSN,
	input wire [31:0] D_MEM_DI,
	output wire [31:0] D_MEM_DOUT,
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN,
	output wire [3:0] D_MEM_BE,

	//RegFile Signals
	output wire RF_WE,
	output wire [4:0] RF_RA1,
	output wire [4:0] RF_RA2,
	output wire [4:0] RF_WA1,
	input wire [31:0] RF_RD1,
	input wire [31:0] RF_RD2,
	output wire [31:0] RF_WD,
	output wire HALT,                   // if set, terminate program
	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT      // equal RF_WD this port is used for test
	);

    /* wire 및 reg 선언부 */
    //register 및 wire
    //nop
    reg [31:0] nop;

    //IF
    reg [11:0] pc; 
    reg [31:0] INST_IF_ID;   
    reg [11:0] pc_IF_ID;
	reg isBubble_IF_ID;

    //ID
    reg [31:0] RF_RD1_ID_EX; //RD1값 저장 reg
	reg [31:0] RF_RD2_ID_EX; //RD2값 저장 reg
    reg [11:0] pc_ID_EX;
    reg [31:0] INST_ID_EX;
	reg isBubble_ID_EX;

    //ex
    wire[31:0] imm;
    reg [31:0] alu_out;
    reg [31:0] RF_RD2_EX_MEM;
    reg [11:0] pc_EX_MEM;
    reg [31:0] INST_EX_MEM;
    wire[4:0] WA_MEM;
    //alu unit
	wire[31:0] alu_result;
    reg [31:0] alu_out;
    //BranchComp
	wire BrEq; // BranchComp to controlUnit
	wire BrLt; // BranchComp to controlUnit
	reg isBubble_EX_MEM;
    
	//MEM
	reg [31:0] RF_WD_MEM_WB;
    reg [31:0] INST_MEM_WB;
    wire[4:0] WA_WB;
	reg isBubble_MEM_WB;
    
	//WB

    // control signals
    /* control unit에서 나오는 wire*/
    //EX
    wire [4:0] alu_control;
    wire is_sign;
    wire [2:0] imm_control;
    wire ASel;
    wire BSel;
    //MEM
    wire memWrite;
    wire [3:0] memByte;
    wire [1:0] wbSel;
    //WB
    wire regWrite;

    /* ID/EX 단계 */
    //EX
    reg [4:0] alu_control_ID_EX;
    reg is_sign_ID_EX;
    reg [2:0] imm_control_ID_EX;
    reg ASel_ID_EX;
    reg BSel_ID_EX;
    //MEM
    reg memWrite_ID_EX;
    reg [3:0] memByte_ID_EX;
    reg [1:0] wbSel_ID_EX;
    //WB
    reg regWrite_ID_EX;

    /* EX/MEM 단계 */
    //MEM
    reg memWrite_EX_MEM;
    reg [3:0] memByte_EX_MEM;
    reg [1:0] wbSel_EX_MEM;
    //WB
    reg regWrite_EX_MEM;
    reg isTaken_EX_MEM;

    /* MEM/WB 단계 */
    //WB
    reg regWrite_MEM_WB;
    reg isTaken_MEM_WB;

    /*for stall*/    
    wire isNop_IF_ID;
    wire isNop_ID_EX;
	wire isNop_ID_EX_c;
	wire isNop_ID_EX_d;
	assign isNop_ID_EX = isNop_ID_EX_c | isNop_ID_EX_d;
    wire IF_ID_WE;
    wire pcWrite;

    //forwardUnit
    wire [1:0] forwardA;
    wire [1:0] forwardB;
    
    /*BTB <-> control unit*/
    wire misPredict; // BTB to controlUnit
    wire isTaken; // controlUnit to BTB
	wire[11:0] nextPc;

    /*초기화 */
	initial begin
		NUM_INST <= 0;
        pc <= 0;
		isBubble_IF_ID <= 0;
		isNop_IF_ID <= 0;
        nop <= 32'b00000000000000000000000000010011;
	end
    
    assign I_MEM_CSN = ~RSTn;
    assign D_MEM_CSN = ~RSTn;
    always @(RSTn) begin
		I_MEM_ADDR = pc;
		INST_IF_ID = I_MEM_DI;
	end

    /*포트 연결부*/
    BranchComp branch_comp(
		.RSTn 		(RSTn),
		.is_sign 	(is_sign_ID_EX),
		.RF_RD1  	(RF_RD1_ID_EX), // source register 1로 부터 읽을 값
		.RF_RD2  	(RF_RD2_ID_EX), // source register 2로 부터 읽을 값
   		.BrEq    	(BrEq),
    	.BrLt    	(BrLt)
	);

    ImmGen imm_gen1(
		.RSTn				(RSTn),
		.imm_control	    (imm_control_ID_EX),
		.I_MEM_DI			(INST_ID_EX),
		.imm				(imm)
	);

    AluUnit alu_unit(
        .RSTn			(RSTn),
        .ASel           (ASel_ID_EX),
        .BSel           (BSel_ID_EX),
        .forwardA		(forwardA),
        .forwardB		(forwardB),
        .is_sign		(is_sign_ID_EX),
        .alu_control	(alu_control_ID_EX),
        .RF_RD1			(RF_RD1_ID_EX), // source register 1로 부터 읽을 값
        .RF_RD2			(RF_RD2_ID_EX), // source register 2로 부터 읽을 값
        .imm			(imm),
        .pc				(pc_ID_EX),
        .SRC1_EX_MEM    (alu_out),
        .SRC2_EX_MEM    (alu_out),
        .SRC1_MEM_WB    (RF_WD_MEM_WB),
        .SRC2_MEM_WB    (RF_WD_MEM_WB),
        .alu_result	    (alu_result)
	);

	ControlUnit control_unit(
		.RSTn			(RSTn),
		.INST_IF_ID		(INST_IF_ID),
        .INST_ID_EX     (INST_ID_EX),
		.BrEq			(BrEq),		
		.BrLt			(BrLt),
		.imm_control	(imm_control),
		.regWrite		(regWrite),
		.memWrite		(memWrite),
		.memByte		(memByte),
		.is_sign		(is_sign),
		.ASel			(ASel),
		.BSel			(BSel),
		.alu_control	(alu_control),
		.wbSel		    (wbSel),
        .misPredict     (misPredict),
        .isTaken        (isTaken),
        .isNop_IF_ID    (isNop_IF_ID),
        .isNop_ID_EX    (isNop_ID_EX_c)
	);

	DetectionUnit detection_unit(
		.RSTn			(RSTn),
		.memWrite		(memWrite_ID_EX),
		.RD_EX			(INST_ID_EX[11:7]),
		.RS1_ID			(INST_IF_ID[19:15]),
		.RS2_ID			(INST_IF_ID[24:20]),
		.IF_ID_WE		(IF_ID_WE),
		.pcWrite		(pcWrite),
		.isNop			(isNop_ID_EX_d)
	);

    ForwardUnit forward_unit(
        .RSTn           (RSTn),
		.RS1_EX			(INST_ID_EX[19:15]),
        .RS2_EX         (INST_ID_EX[24:20]),
        .RD_MEM         (INST_EX_MEM[11:7]),
        .RD_WB          (INST_MEM_WB[11:7]),
        .regWrite_MEM   (regWrite_EX_MEM),
        .regWrite_WB    (regWrite_MEM_WB),
		.forwardA		(forwardA),
		.forwardB		(forwardB)
	);

    BTB btb(
        .RSTn           (RSTn),
        .INST_ID_EX     (INST_ID_EX),
        .pc_ID_EX       (pc_ID_EX),
        .pc             (pc),
        .isTaken        (isTaken),
        .updatedAddr    (alu_result),
        .nextPc    		(nextPC),
        .misPredict     (misPredict)
    );

    /* datapath 연결부 */

    /*IF datapath*/
    always @(*) begin
        I_MEM_ADDR = pc & 12'hFFF;
    end
    always @(posedge CLK) begin
		//pcWrite가 0일 때 hold시키기
        if(pcWrite == 1) begin
            pc <= nextPc;
        end
	end

    // IF/ID register
    //instruction reg
    always @(posedge CLK) begin
        if(IF_ID_WE) begin
            // isNop_IF_ID일 때 nop대입 
            if(isNop_IF_ID) begin
                INST_IF_ID <= nop;
            end
            //IF_ID_WE이 아니면 그 다음 instruction 대입
            else begin
                INST_IF_ID <= I_MEM_DI;
            end
        end
    end
    //pc
    always @(posedge CLK) begin
        pc_IF_ID <= pc;
    end
	//isBubble_IF_ID
	always @(posedge CLK) begin
		isBubble_IF_ID <=  isNop_IF_ID;
	end


    /*ID datapath*/
    //connect to RA1, RA2 of RegisterFile
	assign RF_RA1 = INST_IF_ID[19:15];
	assign RF_RA2 = INST_IF_ID[24:20];
	
    // ID/EX register
    // RF_RD1, RF_RD2
	always @(posedge CLK) begin
		RF_RD1_ID_EX <= RF_RD1;
		RF_RD2_ID_EX <= RF_RD2;
	end
    //pc_IFID
    always @(posedge CLK) begin
        pc_ID_EX <= pc_IF_ID;
    end
    //instruction reg
    always @(posedge CLK) begin
        // isNop_ID_EX에 따른 noop 기능 추가
        if(isNop_ID_EX) begin
            INST_ID_EX <= nop;
        end
        else begin
            INST_ID_EX <= INST_ID_EX;
        end
		
    end
    //control signal
    always @(posedge CLK) begin

		//@Todo: isNop_ID_EX일 때, 컨트롤 시그널 잘 조절하기
        if(isNop_ID_EX) begin
            regWrite_ID_EX <= 0;
            wbSel_ID_EX <= 2'b00;
            memWrite_ID_EX <= 0;
            memByte_ID_EX <= memByte;

            alu_control_ID_EX <= alu_control;
            is_sign_ID_EX <= is_sign;
            imm_control_ID_EX <= imm_control;
            ASel_ID_EX <= ASel;
            BSel_ID_EX <= BSel;
        end
        else begin
            regWrite_ID_EX <= regWrite;
            wbSel_ID_EX <= wbSel;
            memWrite_ID_EX <= memWrite;
            memByte_ID_EX <= memByte;
            
            alu_control_ID_EX <= alu_control;
            is_sign_ID_EX <= is_sign;
            imm_control_ID_EX <= imm_control;
            ASel_ID_EX <= ASel;
            BSel_ID_EX <= BSel;
        end
    end
	//isBubble
    //isNop_ID_EX, 일 때 isBubble값을 1로 바꾸기, 아니면 0
	always @(posedge CLK) begin
		if(isNop_ID_EX) begin
			isBubble_ID_EX <= isNop_ID_EX;
		end
		else begin
			isBubble_ID_EX <= isBubble_IF_ID;	
		end
	end
    

    /*EX datapath*/
    //alu_out
    always @(posedge CLK) begin
        alu_out <= alu_result;
    end
    //RF_RD2_EX_MEM
    always @(posedge CLK) begin
        RF_RD2_EX_MEM <= RF_RD1_ID_EX;
    end
    //pc_EX_MEM
    always @(posedge CLK) begin
        pc_EX_MEM <= pc_ID_EX;
    end
    //instruction reg
    always @(posedge CLK) begin
        INST_EX_MEM <= INST_MEM_WB;
    end
    //control signal
    always @(posedge CLK) begin
        regWrite_EX_MEM <= regWrite_ID_EX;
        wbSel_EX_MEM <= wbSel_ID_EX ;
        memWrite_EX_MEM <= memWrite_ID_EX;
        memByte_EX_MEM <= memByte_ID_EX;
        isTaken_EX_MEM <= isTaken;
    end
	//isBubble
	always @(posedge CLK) begin
		isBubble_EX_MEM <= isBubble_ID_EX;
	end

    /*MEM datapath*/
    //data memory connection
    assign D_MEM_ADDR = alu_out & 16'h3FFF;
    assign D_MEM_DOUT = RF_RD2_EX_MEM;
    assign D_MEM_WEN = memWrite_EX_MEM;
    //instruction reg
    always @(posedge CLK) begin
        INST_MEM_WB <= INST_EX_MEM;
    end

    always @(posedge CLK) begin
        if(wbSel_EX_MEM == 2'b00) begin
            RF_WD_MEM_WB <= alu_out; 
        end
        else if(wbSel_EX_MEM == 2'b01) begin
            RF_WD_MEM_WB <= D_MEM_DI;
        end
        else if(wbSel_EX_MEM == 2'b10) begin
            RF_WD_MEM_WB <= pc_EX_MEM + 4;
        end
    end
    //control signal
    always @(posedge CLK) begin
        regWrite_MEM_WB <= regWrite_EX_MEM;
        isTaken_MEM_WB <= isTaken_EX_MEM;
    end
	//isBubble
	always @(posedge CLK) begin
		isBubble_MEM_WB <= isBubble_EX_MEM;
	end

    /*WB datapath*/
    assign RF_WD = RF_WD_MEM_WB;
    assign RF_WA1 = INST_MEM_WB[11:7];
    assign RF_WE = regWrite_MEM_WB;

    
    //termination & output Port
	wire termination_flag = 0;
	reg termination_flag_reg;
	reg[6:0] opcode;
	reg HALT_reg;

	assign termination_flag = termination_flag_reg;
	assign HALT = HALT_reg;
	assign opcode = INST_MEM_WB[6:0];

    // Only allow for NUM_INST
	always @ (negedge CLK) begin
		if(RSTn) begin	
			if(isBubble_MEM_WB == 0) begin
				NUM_INST <= NUM_INST + 1;
			end
		end
	end
    
    //output port
	assign OUTPUT_PORT = (opcode == 7'b1100011)? isTaken_MEM_WB : RF_WD;

	always@(*) begin
		// 종료 조건 설정
		if(I_MEM_DI_reg == 32'h00c00093 ) begin
			termination_flag_reg = 1;
		end
		else begin
			if(I_MEM_DI_reg == 32'h00008067 && termination_flag_reg == 1) begin
				termination_flag_reg = 1;
			end
			else begin
				termination_flag_reg = 0;
			end
		end

		if(termination_flag_reg & (I_MEM_DI_reg == 32'h00008067)) begin
			HALT_reg = 1;
		end 
		else begin
			HALT_reg = 0;
		end
	end
endmodule
