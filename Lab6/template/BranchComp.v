module BranchComp(
    input wire RSTn,
    input wire is_sign,
    input wire[1:0] forwardA,
    input wire[1:0] forwardB,
    input wire [31:0] RF_RD1, // source register 1로 부터 읽을 값
	input wire [31:0] RF_RD2, // source register 2로 부터 읽을 값
    input wire [31:0] SRC1_EX_MEM,
    input wire [31:0] SRC2_EX_MEM,
    input wire [31:0] SRC1_MEM_WB,
    input wire [31:0] SRC2_MEM_WB,
    output wire BrEq,
    output wire BrLt
);

reg BrEq_reg;
reg BrLt_reg;

assign BrEq = BrEq_reg;
assign BrLt = BrLt_reg;

wire [31:0] src1;
wire [31:0] src2;

assign src1 = (forwardA == 2'b00)? RF_RD1 :
(forwardA == 2'b10)? SRC1_EX_MEM :
(forwardA == 2'b01)? SRC1_MEM_WB : SRC1_MEM_WB;

assign src2 = (forwardB == 2'b00)? RF_RD2 :
(forwardB == 2'b10)? SRC2_EX_MEM :
(forwardB == 2'b01)? SRC2_MEM_WB : SRC2_MEM_WB;


always@(*) begin
    if(RSTn == 1) begin
        if(is_sign) begin
            if(src1 == src2) begin
                BrEq_reg = 1;
                BrLt_reg = 0;
            end 
            else if(src1 != src2) begin
                BrEq_reg = 0;
                if($signed(src1) < $signed(src2)) begin
                    BrLt_reg = 1;
                end
                else begin
                    BrLt_reg = 0;
                end
            end
        end
        else begin
            if(src1 == src2) begin
                BrEq_reg = 1;
                BrLt_reg = 0;
            end 
            else if(src1 != src2) begin
                BrEq_reg = 0;
                if(src1 < src2) begin
                    BrLt_reg = 1;
                end
                else begin
                    BrLt_reg = 0;
                end
            end
        end
    end
end
endmodule
