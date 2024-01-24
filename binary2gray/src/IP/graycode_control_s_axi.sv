module graycode_control_s_axi
#(parameter
    C_S_AXI_ADDR_WIDTH = 12,
    C_S_AXI_DATA_WIDTH = 32
)(
    input  wire                             ACLK,
    input  wire                             ARESET_N,
    input  wire                             ACLK_EN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]    AWADDR,
    input  wire                             AWVALID,
    output wire                             AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]    WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0]  WSTRB,
    input  wire                             WVALID,
    output wire                             WREADY,
    output wire [1:0]                       BRESP,
    output wire                             BVALID,
    input  wire                             BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]    ARADDR,
    input  wire                             ARVALID,
    output wire                             ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0]    RDATA,
    output wire [1:0]                       RRESP,
    output wire                             RVALID,
    input  wire                             RREADY,

    output wire                             user_start,
    input  wire                             user_done,
    input  wire                             user_ready,
    input  wire                             user_idle,

    output reg  [63:0]                      Bin_Code_addr,
    output reg  [63:0]                      Gry_Code_addr
);
//------------------------Address Info-------------------

// 0x10 : User Control signals
//        bit 0  - user_start (Read/Write/)
//        bit 1  - user_done (Read)
//        bit 2  - user_idle (Read)

// 0x1c : Data signal of Bin_Code_addr
//        bit 31~0 - Bin_Code_addr[31:0] (Read/Write)
// 0x20 : Data signal of Bin_Code_addr
//        bit 63~32 - Bin_Code_addr[63:32] (Read/Write)


// 0x28 : Data signal of Gry_Code_addr
//        bit 31~0 - Gry_Code_addr[31:0] (Read/Write)
// 0x2c : Data signal of Gry_Code_addr
//        bit 63~32 - Gry_Code_addr[63:32] (Read/Write)

//------------------------Parameter----------------------
localparam
    // address offset for kernet argument
    ADDR_USER_CTRL       = 6'h10,

    ADDR_BIN_CODE0       = 6'h1c,
    ADDR_BIN_CODE1       = 6'h20,

    ADDR_GRY_CODE0       = 6'h28,
    ADDR_GRY_CODE1       = 6'h2c,

    // fsm for axi r/w
    WRIDLE               = 2'd0,
    WRDATA               = 2'd1,
    WRRESP               = 2'd2,
    WRRESET              = 2'd3,
    RDIDLE               = 2'd0,
    RDDATA               = 2'd1,
    RDRESET              = 2'd2,
    ADDR_BITS            = C_S_AXI_ADDR_WIDTH;

//------------------------Local signal-------------------
reg  [1:0]                    wstate = WRRESET;
reg  [1:0]                    wnext;
reg  [ADDR_BITS-1:0]          waddr;
// wire [31:0]                   wmask;
wire                          aw_hs;
wire                          w_hs;
reg  [1:0]                    rstate = RDRESET;
reg  [1:0]                    rnext;
reg  [63:0]                   rdata;
wire                          ar_hs;
wire [ADDR_BITS-1:0]          raddr;

// internal registers
reg                           int_ap_idle;
reg                           int_ap_done = 1'b0;
reg                           int_ap_start = 1'b0;
reg                           int_auto_restart = 1'b0;

//------------------------Instantiation------------------

//------------------------AXI write fsm------------------
assign AWREADY = (wstate == WRIDLE);
assign WREADY  = (wstate == WRDATA);
assign BRESP   = 2'b00;  // OKAY
assign BVALID  = (wstate == WRRESP);
// assign wmask   = { {8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}} };
assign aw_hs   = AWVALID & AWREADY;
assign w_hs    = WVALID & WREADY;

// wstate
always @(posedge ACLK or negedge ARESET_N) begin
    if (!ARESET_N)
        wstate <= WRRESET;
    else if (ACLK_EN)
        wstate <= wnext;
end

// wnext
always @(*) begin
    case (wstate)
        WRIDLE:
            if (AWVALID)
                wnext = WRDATA;
            else
                wnext = WRIDLE;
        WRDATA:
            if (WVALID)
                wnext = WRRESP;
            else
                wnext = WRDATA;
        WRRESP:
            if (BREADY)
                wnext = WRIDLE;
            else
                wnext = WRRESP;
        default:
            wnext = WRIDLE;
    endcase
end

// waddr
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (aw_hs)
            waddr <= AWADDR[ADDR_BITS-1:0];
    end
end

//------------------------AXI read fsm-------------------
assign ARREADY = (rstate == RDIDLE);
assign RDATA   = rdata;
assign RRESP   = 2'b00;  // OKAY
assign RVALID  = (rstate == RDDATA);
assign ar_hs   = ARVALID & ARREADY;
assign raddr   = ARADDR[ADDR_BITS-1:0];

// rstate
always @(posedge ACLK or negedge ARESET_N) begin
    if (!ARESET_N)
        rstate <= RDRESET;
    else if (ACLK_EN)
        rstate <= rnext;
end

// rnext
always @(*) begin
    case (rstate)
        RDIDLE:
            if (ARVALID)
                rnext = RDDATA;
            else
                rnext = RDIDLE;
        RDDATA:
            if (RREADY & RVALID)
                rnext = RDIDLE;
            else
                rnext = RDDATA;
        default:
            rnext = RDIDLE;
    endcase
end

// rdata
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (ar_hs) begin
            rdata <= 1'b0;
            case (raddr)
                ADDR_USER_CTRL: begin
                    rdata[0] <= int_ap_start;
                    rdata[1] <= int_ap_done;
                    rdata[2] <= int_ap_idle;
                end
                ADDR_BIN_CODE0: rdata <= Bin_Code_addr[31:0];
                ADDR_BIN_CODE1: rdata <= Bin_Code_addr[63:32];
                ADDR_GRY_CODE0: rdata <= Gry_Code_addr[31:0];
                ADDR_GRY_CODE1: rdata <= Gry_Code_addr[63:32];
            endcase
        end
    end
end


//------------------------Register logic-----------------
assign user_start  = int_ap_start;

// int_ap_start
always @(posedge ACLK) begin
    if (!ARESET_N)
        int_ap_start <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_USER_CTRL && WSTRB[0] && WDATA[0])
            int_ap_start <= 1'b1;
        else if (user_ready)
            int_ap_start <= 0; // clear on handshake
    end
end

// int_ap_done
always @(posedge ACLK) begin
    if (!ARESET_N)
        int_ap_done <= 1'b0;
    else if (ACLK_EN) begin
        if (user_done)
            int_ap_done <= 1'b1;
        else if (ar_hs && raddr == ADDR_USER_CTRL)
            int_ap_done <= 1'b0; // clear on read
    end
end

// int_ap_idle
always @(posedge ACLK) begin
    if (!ARESET_N)
        int_ap_idle <= 1'b0;
    else if (ACLK_EN) begin
        int_ap_idle <= user_idle;
    end
end

// Bin_Code_addr
always @(posedge ACLK) begin
    if (!ARESET_N)
        Bin_Code_addr  <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_BIN_CODE0)
            Bin_Code_addr[31:0]    <= WDATA;
        if (w_hs && waddr == ADDR_BIN_CODE1)
            Bin_Code_addr[63:32]    <= WDATA;
    end
end

// Gry_Code_addr
always @(posedge ACLK) begin
    if (!ARESET_N)
        Gry_Code_addr    <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_GRY_CODE0)
            Gry_Code_addr[31:0]  <= WDATA;
        if (w_hs && waddr == ADDR_GRY_CODE1)
            Gry_Code_addr[63:32]  <= WDATA;
    end
end

//------------------------Memory logic-------------------

endmodule
