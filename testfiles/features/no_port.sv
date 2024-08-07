
module no_port
  (
    input   wire pclk,
    input   wire presetn,
    input   wire [2:2] paddr,
    input   wire psel,
    input   wire pwrite,
    input   wire penable,
    output  wire pready,
    input   wire [31:0] pwdata,
    input   wire [3:0] pstrb,
    output  wire [31:0] prdata,
    output  wire pslverr
  );
  wire wr_req;
  wire [2:2] wr_addr;
  wire [31:0] wr_data;
  wire rd_req;
  wire [2:2] rd_addr;
  reg [31:0] rd_data;
  reg wr_ack;
  reg rd_ack;
  reg [31:0] reg0_reg;
  reg reg0_wreq;
  wire reg0_wack;
  reg [31:0] reg1_reg;
  reg reg1_wreq;
  wire reg1_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // Write Channel
  assign wr_req = (psel & pwrite) & ~penable;
  assign wr_addr = paddr;
  assign wr_data = pwdata;
  always_comb
  ;

  // Read Channel
  assign rd_req = (psel & ~pwrite) & ~penable;
  assign rd_addr = paddr;
  assign prdata = rd_data;
  assign pready = wr_ack | rd_ack;
  assign pslverr = 1'b0;

  // pipelining for wr-in+rd-out
  always_ff @(posedge(pclk))
  begin
    if (!presetn)
      begin
        rd_ack <= 1'b0;
        rd_data <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 1'b0;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end
  end

  // Register reg0
  assign reg0_wack = reg0_wreq;
  always_ff @(posedge(pclk))
  begin
    if (!presetn)
      reg0_reg <= 32'b00000000000000000000000000000000;
    else
      if (reg0_wreq == 1'b1)
        reg0_reg <= wr_dat_d0;
  end

  // Register reg1
  assign reg1_wack = reg1_wreq;
  always_ff @(posedge(pclk))
  begin
    if (!presetn)
      reg1_reg <= 32'b00000000000000000000000000000000;
    else
      if (reg1_wreq == 1'b1)
        reg1_reg <= wr_dat_d0;
  end

  // Process for write requests.
  always_comb
  begin
    reg0_wreq = 1'b0;
    reg1_wreq = 1'b0;
    case (wr_adr_d0[2:2])
    1'b0:
      begin
        // Reg reg0
        reg0_wreq = wr_req_d0;
        wr_ack = reg0_wack;
      end
    1'b1:
      begin
        // Reg reg1
        reg1_wreq = wr_req_d0;
        wr_ack = reg1_wack;
      end
    default:
      wr_ack = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (rd_addr[2:2])
    1'b0:
      begin
        // Reg reg0
        rd_ack_d0 = rd_req;
        rd_dat_d0 = reg0_reg;
      end
    1'b1:
      begin
        // Reg reg1
        rd_ack_d0 = rd_req;
        rd_dat_d0 = reg1_reg;
      end
    default:
      rd_ack_d0 = rd_req;
    endcase
  end
endmodule
