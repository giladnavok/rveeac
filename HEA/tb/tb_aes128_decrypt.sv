`timescale 1ns / 1ps

module tb_aes128_decrypt;

  // Clock and reset
  logic clk = 0;
  always #2.5 clk = ~clk;      // 200 MHz clock

  logic rst_n;

  // DUT inputs
  logic        start_i;
  logic [127:0] key_i;
  logic [127:0] cipher_text_i;

  // DUT outputs
  logic [127:0] plain_text_o;
  logic        ready_o;
  logic        done_o;

  // TB Wires 
  logic [8:0] cycle_counter;
  logic start_counter;
  logic [127:0] expected;

  // Instantiate AES core
  aes128_decrypt uut (
    .clk             (clk),
    .rst_n           (rst_n),
    .start_i         (start_i),
    .key_i           (key_i),
    .cipher_text_i   (cipher_text_i),
    .plain_text_o    (plain_text_o),
    .ready_o         (ready_o),
    .done_o          (done_o)
  );

  // Waveform dump
  initial begin
//    $dumpfile("tb_aes128_core.vcd");
//    $dumpvars(0, tb_aes128_core);
    $dumpvars(0, uut);
  end

  always_ff @( posedge clk or negedge rst_n ) begin 
    if (!rst_n) begin
      cycle_counter <= 0;
    end else begin
      cycle_counter <= (start_counter) ? cycle_counter + 1 : cycle_counter;
    end    
  end
  assign expected = 128'h00112233445566778899aabbccddeeff;
  
  initial begin
    // Initialize
    rst_n = 0;
    start_i = 0;
    key_i = 128'h0;
    cipher_text_i = 128'h0;

    start_counter <= 0;
    // Release reset
    #20;
    rst_n = 1;

    // Wait a cycle
    @(posedge clk);

    // Apply single test vector
    key_i = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    cipher_text_i = 128'h8df4e9aac5c7573a27d8d055d6e4d64b;
    start_i = 1;
    start_counter <= 1;
    @(posedge clk);
    start_i = 0;

    // Wait for completion
    wait (done_o == 1'b1);
    start_counter <= 0;

    repeat (3) @(posedge clk);

    assert (plain_text_o == expected) else $error("AES mismatch at time %0t: got %032h, expected %032h", $time, plain_text_o, expected);

    // Display result
    $display("AES-128 Decryption Result:");
    $display("Key        = %032h", key_i);
    $display("CipherText = %032h", cipher_text_i);
    $display("PlainText  = %032h", plain_text_o);

    $finish;
  end

endmodule
