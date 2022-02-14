module Forwarding_unit (
        input wire RSTn,

        input wire [4:0] RF_RA1,
        input wire [4:0] RF_RA2,

        input wire [4:0] DX_WA,
        input wire [4:0] XM_WA,
        input wire [4:0] MB_WA,
        
        input wire DX_RF_WE,
        input wire XM_RF_WE,
        input wire MB_RF_WE,

        input reg [6:0] cur_type,
        input reg [6:0] DX_cur_type,
        input reg [6:0] XM_cur_type,

        output reg [2:0] RD1_src,
        output reg [2:0] RD2_src,
        output reg [2:0] ID1_src,

        output reg is_stall
    );

    reg [6:0]R_type;
	reg [6:0]I_type;
	reg [6:0]LW_type;
	reg [6:0]SW_type;
	reg [6:0]B_type;
	reg [6:0]JAL_type;
	reg [6:0]JALR_type;

    initial begin
        JAL_type <= 7'b1101111;
        JALR_type <= 7'b1100111;
        B_type <= 7'b1100011;
        LW_type <= 7'b0000011;
        SW_type <= 7'b0100011;
        I_type <= 7'b0010011;
        R_type <= 7'b0110011;
	end

    always@(*) begin
        if(RSTn) begin
            //RD1_src
            if( (RF_RA1 == DX_WA) & (RF_RA1 != 0) & DX_RF_WE ) begin 
                RD1_src = 3'b000;
            end
            else if ( (RF_RA1 == XM_WA) & (RF_RA1 != 0) & XM_RF_WE ) begin 
                if(XM_cur_type == LW_type) begin
                    RD1_src = 3'b001;
                end
                else begin
                    RD1_src = 3'b010;
                end
            end
            else if ( (RF_RA1 == MB_WA) & (RF_RA1 != 0) & MB_RF_WE ) begin
                RD1_src = 3'b011;
            end
            else begin 
                RD1_src = 3'b100;
            end

            //RD2_src
            if( (RF_RA2 == DX_WA) & (RF_RA2 != 0) & DX_RF_WE ) begin 
                RD2_src = 3'b000; 
            end
            else if ( (RF_RA2 == XM_WA) & (RF_RA2 != 0) & XM_RF_WE ) begin 
                if(XM_cur_type == LW_type) begin
                    RD2_src = 3'b001; 
                end
                else begin
                    RD2_src = 3'b010; 
                end
            end
            else if ( (RF_RA2 == MB_WA) & (RF_RA2 != 0) & MB_RF_WE ) begin
                RD2_src = 3'b011; 
            end
            else begin 
                RD2_src = 3'b100;
            end
            
            if( (RF_RA1 == DX_WA) & (RF_RA1 != 0) & DX_RF_WE ) begin
                ID1_src = 3'b000; 
            end
            else if ( (RF_RA1 == XM_WA) & (RF_RA1 != 0) & XM_RF_WE ) begin 
                if(XM_cur_type == LW_type) begin
                    ID1_src = 3'b001; 
                end
                else begin
                    ID1_src = 3'b010;
                end
            end
            else if ( (RF_RA1 == MB_WA) & (RF_RA1 != 0) & MB_RF_WE ) begin 
                ID1_src = 3'b011; 
            end
            else begin 
                ID1_src = 3'b100;
            end

            //is_stall
            if( (cur_type == JALR_type) | (cur_type == JAL_type) | ( (DX_cur_type == LW_type) & (DX_WA != 0) & ( (DX_WA == RF_RA1) | (DX_WA == RF_RA2) ) ) ) begin
                is_stall = 1;
            end
            else begin
                is_stall = 0;
            end
        end
    end
endmodule