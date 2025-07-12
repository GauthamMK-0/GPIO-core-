// Description: GPIO Core with AMBA APB v3 (without error handling)

module GPIO_core (
    // APB Interface
    input  wire        pclk,
    input  wire        prst,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    input  wire [31:0] paddr,

    // Auxiliary input
    input  wire [31:0] aux_in,

    // IO Pad
    inout  wire [31:0] io_pad,

    // APB Outputs
    output wire        pready,
    output wire [31:0] prdata,
    output wire        irq,

    // GPIO Outputs
    output wire [31:0] oen_padoe_o,
    output wire [31:0] out_pad_o
);

    // Internal signals
    wire        sys_clk;
    wire        sys_rst;
    wire [31:0] gpio_addr;
    wire [31:0] gpio_dat_i;
    wire [31:0] gpio_dat_o;
    wire        gpio_we;
    wire [31:0] in_pad_i;
    wire [31:0] aux_i;
    wire        gpio_inta_o;

    // Instantiate APB Interface
    APB_intrf apb_interface (
        .pclk       (pclk),
        .prst       (prst),
        .psel       (psel),
        .penable    (penable),
        .pwrite     (pwrite),
        .pwdata     (pwdata),
        .paddr      (paddr),
        .gpio_inta_o(gpio_inta_o),
        .gpio_dat_o (gpio_dat_o),
        .sys_clk    (sys_clk),
        .sys_rst    (sys_rst),
        .pready     (pready),
        .prdata     (prdata),
        .irq        (irq),
        .gpio_addr  (gpio_addr),
        .gpio_dat_i (gpio_dat_i),
        .gpio_we    (gpio_we)
    );

    // Instantiate Auxiliary Interface
    aux_intrf aux_interface (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        .aux_in (aux_in),
        .aux_i  (aux_i)
    );

    // Instantiate IO Interface
    io_intrf io_interface (
        .out_pad_o   (out_pad_o),
        .oen_padoe_o (oen_padoe_o),
        .in_pad_i    (in_pad_i),
        .io_pad      (io_pad)
    );

    // Instantiate GPIO Register Module
    GPIO_reg gpio_registers (
        .sys_clk     (sys_clk),
        .sys_rst     (sys_rst),
        .gpio_we     (gpio_we),
        .gpio_addr   (gpio_addr), 
        .gpio_data_i (gpio_dat_i),
        .aux_i       (aux_i),
        .in_pad_i    (in_pad_i),
        .gpio_eclk   (1'b0),          // external clocked not used
        .gpio_inta_o (gpio_inta_o),
        .gpio_data_o (gpio_dat_o),
        .out_pad_o   (out_pad_o),
        .oen_padoe_o (oen_padoe_o)
    );

endmodule
