`timescale 1ns/1ps

module GPIO_tb;

    reg         pclk;
    reg         prst;
    reg         psel;
    reg         penable;
    reg         pwrite;
    reg [31:0]  pwdata;
    reg [31:0]  paddr;
    reg [31:0]  aux_in;
    wire [31:0] prdata;
    wire        pready;
    wire        irq;
    wire [31:0] oen_padoe_o;
    wire [31:0] out_pad_o;
    wire [31:0] io_pad;

    reg [31:0]  io_pad_drv;

    // Clock generation
    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;
    end

    // DUT instantiation
    GPIO_core dut (
        .pclk       (pclk),
        .prst       (prst),
        .psel       (psel),
        .penable    (penable),
        .pwrite     (pwrite),
        .pwdata     (pwdata),
        .paddr      (paddr),
        .aux_in     (aux_in),
        .io_pad     (io_pad),
        .pready     (pready),
        .prdata     (prdata),
        .irq        (irq),
        .oen_padoe_o(oen_padoe_o),
        .out_pad_o  (out_pad_o)
    );

    // I/O PAD multiplexing (driving inputs manually)
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : io_mux
            assign io_pad[i] = oen_padoe_o[i] ? out_pad_o[i] : io_pad_drv[i];
        end
    endgenerate

    // Main test sequence
    initial begin
        $display("=== GPIO Test: Write and Read Only ===");

        // Initialize
        prst        = 0;
        psel        = 0;
        penable     = 0;
        pwrite      = 0;
        pwdata      = 0;
        paddr       = 0;
        aux_in      = 0;
        io_pad_drv  = 0;

        // Apply reset
        @(posedge pclk);
        prst = 1;
        repeat (2) @(posedge pclk);

        // ----------- Write to GPIO_OUT (0x04) -----------
        @(posedge pclk);
        psel    = 1;
        pwrite  = 1;
        penable = 0;
        paddr   = 32'h04;
        pwdata  = 32'hABCD1234; // Unique value for GPIO_OUT
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        while (!pready) @(posedge pclk);
        @(posedge pclk);
        psel    = 0;
        penable = 0;
        pwrite  = 0;
        $display("GPIO_OUT Driven = 0x%08h", 32'hABCD1234);

        // ----------- Configure GPIO_OE for output (lower 4 bits) -----------
        @(posedge pclk);
        psel    = 1;
        pwrite  = 1;
        penable = 0;
        paddr   = 32'h08;
        pwdata  = 32'hFACE000F;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        while (!pready) @(posedge pclk);
        @(posedge pclk);
        psel    = 0;
        penable = 0;
        pwrite  = 0;
        $display("GPIO_OE Config = 0x%08h", 32'hFACE000F);
        $display("GPIO [3:0] Driven = %b", out_pad_o[3:0]);

        // ----------- Configure GPIO_OE for input -----------
        @(posedge pclk);
        psel    = 1;
        pwrite  = 1;
        penable = 0;
        paddr   = 32'h08;
        pwdata  = 32'h00000000;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        while (!pready) @(posedge pclk);
        @(posedge pclk);
        psel    = 0;
        penable = 0;
        pwrite  = 0;

        // Drive external input to GPIO
        io_pad_drv = 32'h12345678; // Unique input pattern
        #10;

        // ----------- Read from GPIO_IN (0x00) -----------
        @(posedge pclk);
        psel    = 1;
        pwrite  = 0;
        penable = 0;
        paddr   = 32'h00;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        while (!pready) @(posedge pclk);
        @(posedge pclk);
        $display("Read GPIO_IN [0x%08h] = 0x%08h", paddr, prdata);
        psel    = 0;
        penable = 0;

        $display("=== Simple GPIO Send/Receive Test Done ===");
        $stop;
        $finish;
    end

endmodule
