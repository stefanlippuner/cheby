
module m1
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [19:2] VMEAddr,
    output  reg [31:0] VMERdData,
    input   wire [31:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,
    output  wire VMERdError,
    output  wire VMEWrError,

    // REG r1
    output  wire [7:0] r1_o,

    // REG r2
    output  wire [15:0] r2_o
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg [7:0] r1_reg;
  reg r1_wreq;
  wire r1_wack;
  reg [15:0] r2_reg;
  reg r2_wreq;
  wire r2_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [19:2] wr_adr_d0;
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
        wr_adr_d0 <= 18'b000000000000000000;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
        wr_dat_d0 <= VMEWrData;
      end
  end

  // Register r1
  assign r1_o = r1_reg;
  assign r1_wack = r1_wreq;
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      r1_reg <= 8'b00000000;
    else
      if (r1_wreq == 1'b1)
        r1_reg <= wr_dat_d0[7:0];
  end

  // Register r2
  assign r2_o = r2_reg;
  assign r2_wack = r2_wreq;
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      r2_reg <= 16'b0000000000000000;
    else
      if (r2_wreq == 1'b1)
        r2_reg <= wr_dat_d0[15:0];
  end

  // Process for write requests.
  always_comb
  begin
    r1_wreq = 1'b0;
    r2_wreq = 1'b0;
    case (wr_adr_d0[19:2])
    18'b000000000000000000:
      begin
        // Reg r1
        r1_wreq = wr_req_d0;
        wr_ack_int = r1_wack;
      end
    18'b000000000000000001:
      begin
        // Reg r2
        r2_wreq = wr_req_d0;
        wr_ack_int = r2_wack;
      end
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (VMEAddr[19:2])
    18'b000000000000000000:
      begin
        // Reg r1
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[7:0] = r1_reg;
        rd_dat_d0[31:8] = 24'b0;
      end
    18'b000000000000000001:
      begin
        // Reg r2
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[15:0] = r2_reg;
        rd_dat_d0[31:16] = 16'b0;
      end
    default:
      rd_ack_d0 = VMERdMem;
    endcase
  end
endmodule
