// Description: APB slave interface 

module APB_intrf(
	input wire pclk,
	input wire prst,
	input wire psel,
	input wire penable,
	input wire pwrite,
	input wire [31:0] pwdata,     
	input wire [31:0] paddr,      
	input wire gpio_inta_o,        // interrupt request generation
	input wire [31:0] gpio_dat_o,  // 32-bit data from GPIO core

	output wire sys_clk,           
	output wire sys_rst,
	output wire pready,           // signal for transfer 
	output reg [31:0] prdata,
	output wire irq,              // interrupt signal 
	output wire [31:0] gpio_addr,
	output reg [31:0] gpio_dat_i, //32-bit to GPIO core
	output reg gpio_we

);

parameter idle = 2'b00,
	  setup = 2'b01,
	  enable = 2'b10;

reg [1:0] curr_st, nxt_st;

always @(posedge pclk) begin 
	if (!prst) begin
		curr_st <= idle;
	end else begin 
		curr_st <= nxt_st;
	end
end

//FSM next-stste logic
always @(*) begin 
	nxt_st = idle;

	case (curr_st)
		// IDLE state
		idle: if (psel && !penable) begin 
				nxt_st = setup;
		end else if (!psel && !penable) begin
				nxt_st = idle;
		end
		// SETUP state
   	        setup: if (psel && penable) begin
				nxt_st = enable;
			end else if (psel && !penable) begin
				nxt_st = setup;
			end
		// ENABLE state
		enable: if (psel && penable) begin 
				nxt_st = enable;
			end else if (psel && !penable) begin
				nxt_st = setup;
			end else if (!psel && !penable) begin
				nxt_st = idle;
			end
	endcase
end

assign sys_clk = pclk;
assign sys_rst = prst;
assign gpio_addr = paddr;
assign irq = gpio_inta_o;

always @(*) begin
	if (pwrite && curr_st == enable) begin   // preparation 
		gpio_dat_i = pwdata;
		gpio_we = 1'b1;
	end else if (!pwrite && curr_st == enable) begin     // trasfer of data 
		prdata = gpio_dat_o;
		gpio_we = 1'b0;
	end else begin 
		prdata = 32'b0;
		gpio_dat_i = 32'b0;
		gpio_we = 1'b0;
	end
end

assign pready = (curr_st == enable) ? 1'b1 : 1'b0;

endmodule
		
				
			 	
 
