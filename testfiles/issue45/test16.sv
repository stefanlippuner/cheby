
module test8
  (
    input   wire Clk,
    input   wire Rst,
    output  reg [31:0] VMERdData,
    input   wire [31:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // REG r1
    output  wire [15:0] r1_o
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg [15:0] r1_reg;
  reg r1_wreq;
  wire r1_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [31:0] wr_dat_d0;
  assign rst_n = ~Rst;
  assign VMERdDone = rd_ack_int;
  assign VMEWrDone = wr_ack_int;

  // pipelining for wr-in+rd-out
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      begin
        rd_ack_int <= 1'b0;
        VMERdData <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_dat_d0 <= VMEWrData;
      end
  end

  // Register r1
  assign r1_o = r1_reg;
  assign r1_wack = r1_wreq;
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      r1_reg <= 16'b0000000000000000;
    else
      if (r1_wreq == 1'b1)
        r1_reg <= wr_dat_d0[15:0];
  end

  // Process for write requests.
  always_comb
  begin
    r1_wreq = 1'b0;
    // Reg r1
    r1_wreq = wr_req_d0;
    wr_ack_int = r1_wack;
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    // Reg r1
    rd_ack_d0 = VMERdMem;
    rd_dat_d0[15:0] = r1_reg;
    rd_dat_d0[31:16] = 16'b0;
  end
endmodule
