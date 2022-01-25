module BranchComp(
    input wire RSTn,
    input wire is_sign,
    input wire [31:0] RF_RD1, // source register 1로 부터 읽을 값
	input wire [31:0] RF_RD2, // source register 2로 부터 읽을 값
    output wire BrEq,
    output wire BrLt
);

reg BrEq_reg;
reg BrLt_reg;

assign BrEq = BrEq_reg;
assign BrLt = BrLt_reg;

always@(*) begin
    if(RSTn == 1) begin
        if(is_sign) begin
            if(RF_RD1 == RF_RD2) begin
                BrEq_reg = 1;
                BrLt_reg = 0;
            end 
            else if(RF_RD1 != RF_RD2) begin
                BrEq_reg = 0;
                if($signed(RF_RD1) < $signed(RF_RD2)) begin
                    BrLt_reg = 1;
                end
                else begin
                    BrLt_reg = 0;
                end
            end
        end
        else begin
            if(RF_RD1 == RF_RD2) begin
                BrEq_reg = 1;
                BrLt_reg = 0;
            end 
            else if(RF_RD1 != RF_RD2) begin
                BrEq_reg = 0;
                if(RF_RD1 < RF_RD2) begin
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
