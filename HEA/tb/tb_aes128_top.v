`timescale 1ns/1ps

module aes128_top_tb;

    logic clk;
    logic rst;
    logic [3:0] sw;
    logic btn;
    logic [3:0] led;
    logic ready_o;
    logic done_o;

    // DUT instance
    aes128_top dut (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw),
        .btn     (btn),
        .led     (led),
        .ready_o (ready_o),
        .done_o  (done_o)
    );

    // Clock generation: 100 MHz = 10ns period
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        sw  = 4'b0000;
        btn = 0;

        // Apply reset
        #50;
        rst = 0;
        #50;

        // Wait for ready
        wait (ready_o == 1);

        // Apply test input
        sw = 4'b0000;
        #10;

        // Pulse button to start encryption
        btn = 1;
        #10;
        btn = 0;

        // Wait for done signal
        wait (done_o == 1);
        $display("DONE detected at time %t", $time);
        $display("Output LED = %b", led);

        // Wait enough time to see `done_latched` expire (~1s = 100M cycles = 1ms sim @ 1ns)
        #1_000_000;

        // Done
        $display("Test completed.");
        $finish;
    end

endmodule
