// Description: Auxilary interface

module aux_intrf (
	input wire sys_clk,
	input wire sys_rst,
	input wire [31:0] aux_in,   // auxilary data from external 

	output reg [31:0] aux_i     // auxilary data to GPIO core
);

always @(posedge sys_clk or negedge sys_rst) begin 
  	if (!sys_rst) begin
		aux_i <= 32'b0;
	end else begin
		aux_i <= aux_in;
	end
end

endmodule 
