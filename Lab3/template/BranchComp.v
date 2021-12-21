module BranchComp(
    input wire RSTn,
    input wire is_sign,
    input wire [31:0] RF_RD1, // source register 1로 부터 읽을 값
	input wire [31:0] RF_RD2, // source register 2로 부터 읽을 값
    output wire BrEq,
    output wire BrLt
);

wire result;

always@(*) begin
    if(RSTn == 1) begin
        if(is_sign) begin
            if(RF_RD1 == RF_RD2) begin
                BrEq = 1;
                BrLt = 0;
            end 
            else if(RF_RD1 != RF_RD2) begin
                BrEq = 0;
                if($signed(RF_RD1) < $signed(RF_RD2)) begin
                    BrLt = 1;
                end
                else begin
                    BrLt = 0;
                end
            end
            end
            else begin
                if(RF_RD1 == RF_RD2) begin
                BrEq = 1;
                BrLt = 0;
            end 
            else if(RF_RD1 != RF_RD2) begin
                BrEq = 0;
                if(RF_RD1 < RF_RD2) begin
                    BrLt = 1;
                end
                else begin
                    BrLt = 0;
                end
            end
        end
    end
end
