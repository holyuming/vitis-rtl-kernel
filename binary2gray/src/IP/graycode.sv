module graycode #(
    parameter integer C_M00_AXI_ADDR_WIDTH = 64 ,
    parameter integer C_M00_AXI_DATA_WIDTH = 32
)
(
    // System Signals
    input  wire                              ap_clk         ,
    input  wire                              ap_rst_n       ,

    // AXI4 master interface m00_axi
    output wire                              m00_axi_awvalid,
    input  wire                              m00_axi_awready,
    output wire [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_awaddr ,
    output wire [8-1:0]                      m00_axi_awlen  ,
    output wire                              m00_axi_wvalid ,
    input  wire                              m00_axi_wready ,
    output wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_wdata  ,
    output wire [C_M00_AXI_DATA_WIDTH/8-1:0] m00_axi_wstrb  ,
    output wire                              m00_axi_wlast  ,

    input  wire                              m00_axi_bvalid ,
    output wire                              m00_axi_bready ,

    output wire                              m00_axi_arvalid,
    input  wire                              m00_axi_arready,
    output wire [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_araddr ,
    output wire [8-1:0]                      m00_axi_arlen  ,
    input  wire                              m00_axi_rvalid ,
    output wire                              m00_axi_rready ,
    input  wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_rdata  ,
    input  wire                              m00_axi_rlast  ,

    // Control Signals
    input  wire                              user_start     ,
    output wire                              user_idle      ,
    output wire                              user_done      ,
    output wire                              user_ready     ,

    input  wire [64-1:0]                     Bin_Code_addr  ,
    input  wire [64-1:0]                     Gry_Code_addr
);

//------------------------Parameter----------------------
// kernel fsm
localparam IDLE = 0, READ_BIN = 1, WRITE_GRY = 2, FINISH = 3;

// axi read fsm
localparam RIDLE = 0, RADDR = 1, RDATA = 2;

// axi write fsm
localparam WIDLE = 0, WADDR = 1, WDATA = 2, WRESP = 3;

//------------------------Local signal-------------------
reg [2:0] krnl_state, n_krnl_state;
reg [1:0] rstate, n_rstate;
reg [1:0] wstate, n_wstate;

wire b_hs;
wire ar_hs, r_hs;
wire aw_hs, w_hs;

reg [31:0] answer;

//------------------------AXI read fsm-------------------
assign ar_hs    = (m00_axi_arvalid & m00_axi_arready);
assign r_hs     = (m00_axi_rready & m00_axi_rvalid);

always @(*) begin
    case (rstate)
        RIDLE:      n_rstate = (krnl_state == READ_BIN) ? RADDR : RIDLE;
        RADDR:      n_rstate = (ar_hs) ? RDATA : RADDR;
        RDATA:      n_rstate = (r_hs) ? RIDLE : RDATA;
        default:    n_rstate = RIDLE; 
    endcase
end

always @(posedge ap_clk or negedge ap_rst_n) begin
    if (!ap_rst_n)  rstate <= RIDLE;
    else            rstate <= n_rstate;
end

//------------------------AXI write fsm------------------
assign aw_hs    = (m00_axi_awready & m00_axi_awvalid);
assign w_hs     = (m00_axi_wvalid & m00_axi_wready);
assign b_hs     = (m00_axi_bvalid & m00_axi_bready);

always @(*) begin
    case (wstate)
        WIDLE:  n_wstate = (krnl_state == WRITE_GRY) ? WADDR : WIDLE;
        WADDR:  n_wstate = (aw_hs) ? WDATA : WADDR;
        WDATA:  n_wstate = (w_hs) ? WRESP : WDATA;
        WRESP:  n_wstate = (b_hs) ? WIDLE : WRESP;
        default:n_wstate = WIDLE;
    endcase
end

always @(posedge ap_clk or negedge ap_rst_n) begin
    if (!ap_rst_n)  wstate <= RIDLE;
    else            wstate <= n_wstate;
end

//------------------------Kernel fsm---------------------
always @(*) begin
    case (krnl_state)
        IDLE:       n_krnl_state = (user_start) ? READ_BIN : IDLE;
        READ_BIN:   n_krnl_state = (r_hs) ? WRITE_GRY : READ_BIN;
        WRITE_GRY:  n_krnl_state = (b_hs) ? FINISH : WRITE_GRY;
        FINISH:     n_krnl_state = IDLE;
        default:    n_krnl_state = IDLE;
    endcase
end

always @(posedge ap_clk or negedge ap_rst_n) begin
    if (!ap_rst_n)  krnl_state  <= IDLE;
    else            krnl_state  <= n_krnl_state;
end

//------------------------Register logic-----------------
// gray code answer
always @(posedge ap_clk) begin
    if (r_hs)
        answer <= (m00_axi_rdata >> 1) ^ m00_axi_rdata;
end

//------------------------Output logic-------------------
// kernel status
assign user_idle    = (krnl_state == IDLE);
assign user_ready   = (krnl_state == IDLE);
assign user_done    = (krnl_state == FINISH);

// axi write channel
assign m00_axi_awvalid  = (wstate == WADDR);
assign m00_axi_awaddr   = Gry_Code_addr;
assign m00_axi_awlen    = 0;
assign m00_axi_wvalid   = (wstate == WDATA);
assign m00_axi_wdata    = answer;
assign m00_axi_wstrb    = 4'b1111;
assign m00_axi_wlast    = (wstate == WDATA);

// axi b channel
assign m00_axi_bready   = (wstate == WDATA) | (wstate == WRESP);

// axi read channel
assign m00_axi_arvalid  = (rstate == RADDR);
assign m00_axi_araddr   = Bin_Code_addr;
assign m00_axi_arlen    = 0;
assign m00_axi_rready   = (rstate == RDATA);

endmodule