`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered

	o_available_item,			// Sign of the item availability
	o_output_item,			// Sign of the item withdrawal
	o_return_coin,				// Sign of the coin return
	stopwatch,
	current_total,
	return_temp,
);

	// Ports Declaration
	// Do not modify the module interface
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;

	output reg [`kNumItems-1:0] o_available_item;
	output reg [`kNumItems-1:0] o_output_item;
	output reg [`kNumCoins-1:0] o_return_coin;

	output [3:0] stopwatch;
	output [`kTotalBits-1:0] current_total;
	output [`kTotalBits-1:0] return_temp;
	// Normally, every output is register,
	//   so that it can provide stable value to the outside.

//////////////////////////////////////////////////////////////////////	/

	//we have to return many coins
	reg [`kCoinBits-1:0] returning_coin_0;
	reg [`kCoinBits-1:0] returning_coin_1;
	reg [`kCoinBits-1:0] returning_coin_2;
	reg block_item_0;
	reg block_item_1;
	//check timeout
	reg [3:0] stopwatch;
	//when return triggered
	reg have_to_return;
	reg  [`kTotalBits-1:0] return_temp;
	reg [`kTotalBits-1:0] temp;
////////////////////////////////////////////////////////////////////////

	// Net constant values (prefix kk & CamelCase)
	// Please refer the wikepedia webpate to know the CamelCase practive of writing.
	// http://en.wikipedia.org/wiki/CamelCase
	// Do not modify the values.
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;


	// NOTE: integer will never be used other than special usages.
	// Only used for loop iteration.
	// You may add more integer variables for loop iteration.
	integer i, j, k,l,m,n;

	// Internal states. You may add your own net & reg variables.
	reg [`kTotalBits-1:0] current_total;
	reg [`kItemBits-1:0] num_items [`kNumItems-1:0];
	reg [`kCoinBits-1:0] num_coins [`kNumCoins-1:0];

	// Next internal states. You may add your own net and reg variables.
	reg [`kTotalBits-1:0] current_total_nxt;
	reg [`kItemBits-1:0] num_items_nxt [`kNumItems-1:0];
	reg [`kCoinBits-1:0] num_coins_nxt [`kNumCoins-1:0];

	// Variables. You may add more your own registers.
	reg [`kTotalBits-1:0] input_total, output_total, return_total_0,return_total_1,return_total_2;
	

	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		
		// Calculate the next current_total state. current_total_nxt =
		
		//$display("stopwatch : %d", stopwatch);
		if (i_input_coin[0]) input_total = 'd100;
		if (i_input_coin[1]) input_total =  'd500;
		if (i_input_coin[2]) input_total =  'd1000;

		if (i_select_item[0]) output_total = 'd400;
		if (i_select_item[1]) output_total =  'd500;
		if (i_select_item[2]) output_total =  'd1000;
		if (i_select_item[3]) output_total =  'd2000;

		current_total_nxt = current_total_nxt + input_total - output_total;
		input_total = 0;
		output_total = 0;
		//$display("combinational logic: current_total_nxt : %d", current_total_nxt);

	end

	// Combinational logic for the outputs
	always @(*) begin
	// TODO: o_available_item
		if(current_total_nxt > 0) begin
			if(current_total >= 'd2000) o_available_item[3]=1;
			else o_available_item[3] = 0;

			if(current_total >= 'd1000) o_available_item[2]=1;
			else o_available_item[2] = 0;

			if(current_total >= 'd500) o_available_item[1]=1;
			else o_available_item[1] = 0;

			if(current_total >= 'd400) o_available_item[0]=1;
			else o_available_item[0] = 0;
			
			if(i_select_item[0] && o_available_item[0] == 1) o_output_item[0] = 1;
			else o_output_item[0] = 0;

			if(i_select_item[1] && o_available_item[1] == 1) o_output_item[1] = 1;
			else o_output_item[2] = 0;
	
			if(i_select_item[2] && o_available_item[2] == 1) o_output_item[2] = 1;
			else o_output_item[2] = 0;

			if(i_select_item[3] && o_available_item[3] == 1) o_output_item[3] = 1;
			else o_output_item[3] = 0;
		//$display("current_total_nxt : %d", current_total_nxt);
		end
		else begin
			current_total_nxt = 0;
		end

	end
	
	always @(i_input_coin or i_select_item) begin
		stopwatch = 'd`kWaitTime;
	end
	
	always @(i_trigger_return) begin 
		if(i_trigger_return) have_to_return = 1;
		else have_to_return = 0;
	end

	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
			current_total = 0;
			current_total_nxt = 0;
			input_total = 0;
			output_total = 0;
			returning_coin_0 = 0;
			returning_coin_1 = 0;
			returning_coin_2 = 0;
			o_available_item = 4'b0000;
			o_output_item = 4'b0000;
		end
		else begin
			// TODO: update all states.
			current_total = current_total_nxt;
			//$display("i_trigger_return : %d", i_trigger_return);

/////////////////////////////////////////////////////////////////////////

			// decrease stopwatch
			if(stopwatch > 0) begin 
				stopwatch = stopwatch - 1;
				//$display("stopwatch : %d", stopwatch);
			end

			
			if(stopwatch == 0) have_to_return = 1;
			
			//if you have to return some coins then you have to turn on the bit
			if(have_to_return) begin
				stopwatch = 'd`kWaitTime;
				return_temp = current_total;
				//$display("stopwatch : %d", return_temp);
				while(return_temp >0) begin
					if(return_temp >= 1000) begin 
						returning_coin_2 = returning_coin_2 + 1;
						return_temp = return_temp - 'd1000;
					end
					else begin
						if(return_temp >= 500) begin
							returning_coin_1 = returning_coin_1 + 1;
							return_temp = return_temp - 'd500;
						end
						else begin
							if(return_temp >= 100) begin 
								returning_coin_0 = returning_coin_0 + 1;
								return_temp = return_temp - 'd100;
							end
							else begin
								returning_coin_0 = 0;
								returning_coin_1 = 0;
								returning_coin_2 = 0;
							end
						end
					end
					//$display("return_temp : %d", return_temp);
				end
				current_total_nxt = 0;
				//$display("sequential logic: current_total_nxt : %d", current_total_nxt);
				//$display("sequential logic: returning_coins : %d %d %d", returning_coin_0, returning_coin_1, returning_coin_2);
			end
			
			if(returning_coin_2) begin
				o_return_coin[2] = 1;
				returning_coin_2 = returning_coin_2 - 1;
			end
			else o_return_coin[2] = 0;
			
			if(returning_coin_1) begin
				o_return_coin[1] = 1;
				returning_coin_1 = returning_coin_1 - 1;
			end
			else o_return_coin[1] = 0;

			if(returning_coin_0) begin
				o_return_coin[0] = 1;
				returning_coin_0 = returning_coin_0 - 1;
			end
			else o_return_coin[0] = 0;		
			
			//$display("sequential logic: returning_coins : %d %d %d", returning_coin_0, returning_coin_1, returning_coin_2);
			
			if(o_return_coin == 3'b000) begin
				have_to_return = 0;
			end
			
			

/////////////////////////////////////////////////////////////////////////
		end		   //update all state end
	end	   //always end

endmodule
