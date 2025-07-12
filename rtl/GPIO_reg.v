// Description: GPIO registers

// GPIO register address
`define GPIO_IN     32'h0
`define GPIO_OUT    32'h4
`define GPIO_OE     32'h8
`define GPIO_INTE   32'hc
`define GPIO_PTRIG  32'h10
`define GPIO_AUX    32'h14
`define GPIO_CNTRL  32'h18
`define GPIO_INTS   32'h1c
`define GPIO_ECLK   32'h20
`define GPIO_NEC    32'h24

`define RGPIO_CNTRL_INTE 1'b0
`define RGPIO_CNTRL_INTS 1'b1

module GPIO_reg (
    input  wire        sys_clk,
    input  wire        sys_rst,
    input  wire        gpio_we,
    input  wire [31:0] gpio_addr,
    input  wire [31:0] gpio_data_i,
    input  wire [31:0] aux_i,
    input  wire [31:0] in_pad_i,     // 32-bit data from GPIO
    input  wire        gpio_eclk,    // external clock
    output wire        gpio_inta_o,  // interrupt signal
    output reg  [31:0] gpio_data_o,
    output wire [31:0] out_pad_o,
    output wire [31:0] oen_padoe_o   // output-enable signal
);

reg [31:0] rgpio_in;
reg [31:0] rgpio_out;
reg [31:0] rgpio_oe;
reg [31:0] rgpio_inte;
reg [31:0] rgpio_ptrig;
reg [31:0] rgpio_aux;
reg [31:0] rgpio_eclk;
reg [1:0]  rgpio_cntrl;
reg [31:0] rgpio_ints;

reg [31:0] sampled_1;
reg [31:0] sampled_2;

assign out_pad_o   = rgpio_out;
assign oen_padoe_o = rgpio_oe;
assign gpio_inta_o = rgpio_cntrl[`RGPIO_CNTRL_INTE] ? (|(rgpio_ints & rgpio_inte)) : 1'b0;


// GPIO_OUT
always @(posedge sys_clk or negedge sys_rst)
    if (!sys_rst) rgpio_out <= 32'd0;
    else if (gpio_we && gpio_addr == `GPIO_OUT) rgpio_out <= gpio_data_i;

// GPIO_OE
always @(posedge sys_clk or negedge sys_rst)
    if (!sys_rst) rgpio_oe <= 32'd0;
    else if (gpio_we && gpio_addr == `GPIO_OE) rgpio_oe <= gpio_data_i;

//GPIO_INTE
always @(posedge sys_clk or negedge sys_rst)
    if (!sys_rst) rgpio_inte <= 32'd0;
    else if (gpio_we && gpio_addr == `GPIO_INTE) rgpio_inte <= gpio_data_i;

//GPIO_PTRIG
always @(posedge sys_clk or negedge sys_rst)
    if (!sys_rst) rgpio_ptrig <= 32'd0;
    else if (gpio_we && gpio_addr == `GPIO_PTRIG) rgpio_ptrig <= gpio_data_i;

//GPIO_AUX
always @(posedge sys_clk or negedge sys_rst)
    if (!sys_rst) rgpio_aux <= 32'd0;
    else if (gpio_we && gpio_addr == `GPIO_AUX) rgpio_aux <= gpio_data_i;

//GPIO_CNTRL
always @(posedge sys_clk or negedge sys_rst)
    if (!sys_rst) rgpio_cntrl <= 2'd0;
    else if (gpio_we && gpio_addr == `GPIO_CNTRL) rgpio_cntrl <= gpio_data_i[1:0];

//GPIO_RCLK
always @(posedge sys_clk or negedge sys_rst)
    if (!sys_rst) rgpio_eclk <= 32'd0;
    else if (gpio_we && gpio_addr == `GPIO_ECLK) rgpio_eclk <= gpio_data_i;

// capturing pervious data for comparision
always @(posedge sys_clk or negedge sys_rst) begin
    if (!sys_rst) begin
        sampled_1 <= 32'd0;
        sampled_2 <= 32'd0;
        rgpio_in  <= 32'd0;
    end else begin
        sampled_2 <= sampled_1;
        sampled_1 <= in_pad_i;
        rgpio_in  <= in_pad_i;
    end
end

always @(posedge sys_clk or negedge sys_rst) begin
    if (!sys_rst) begin
        rgpio_ints <= 32'd0;
    end else if (gpio_we && gpio_addr == `GPIO_INTS) begin
        rgpio_ints <= rgpio_ints & ~gpio_data_i;
    end else begin
        if (rgpio_cntrl[`RGPIO_CNTRL_INTS]) begin
            // Edge-triggered interrupt
            rgpio_ints <= rgpio_ints |
                          ((~sampled_2 & sampled_1) &  rgpio_ptrig) |  // Rising edge
                          ((sampled_2 & ~sampled_1) & ~rgpio_ptrig);   // Falling edge
        end else begin
            // Level-sensitive interrupt
            rgpio_ints <= rgpio_ints |
                          ((in_pad_i & rgpio_ptrig) | (~in_pad_i & ~rgpio_ptrig));
        end
    end
end


always @(*) begin
    case (gpio_addr)
        `GPIO_IN:    gpio_data_o = rgpio_in;
        `GPIO_OUT:   gpio_data_o = rgpio_out;
        `GPIO_OE:    gpio_data_o = rgpio_oe;
        `GPIO_INTE:  gpio_data_o = rgpio_inte;
        `GPIO_PTRIG: gpio_data_o = rgpio_ptrig;
        `GPIO_AUX:   gpio_data_o = rgpio_aux;
        `GPIO_CNTRL: gpio_data_o = {30'd0, rgpio_cntrl};
        `GPIO_INTS:  gpio_data_o = rgpio_ints;
        `GPIO_ECLK:  gpio_data_o = rgpio_eclk;
        default:     gpio_data_o = 32'd0;
    endcase
end

endmodule
