// Description: IO interface

module io_intrf(
	input wire [31:0] out_pad_o,   // 32-bit data from GPIO
	input wire [31:0] oen_padoe_o, //output enable signal

	output wire [31:0] in_pad_i,   // 32-bit input data to GPIO
	inout wire [31:0] io_pad       // bi-directional wires
);

genvar i;
generate 

// tri-state buffer
for ( i = 0; i<32; i = i+1) begin : gen
	assign io_pad[i] = (oen_padoe_o[i]) ? out_pad_o[i] : 1'bz;
	assign in_pad_i[i] = io_pad[i];
end

endgenerate


endmodule 
	
