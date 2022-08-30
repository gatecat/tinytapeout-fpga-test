`default_nettype none

//  Top level io for this module should stay the same to fit into the scan_wrapper.
//  The pin connections within the user_module are up to you,
//  although (if one is present) it is recommended to place a clock on io_in[0].
//  This allows use of the internal clock divider if you wish.
module user_module_341404507891040852(
  input [7:0] io_in, 
  output [7:0] io_out
);


    wire cfg_mode = io_in[0];
    wire cfg_frameinc = io_in[1];
    wire cfg_framestrb = io_in[2];
    wire cfg_dataclk = io_in[3];
    wire cfg_data = io_in[4];

    localparam W = 3;
    localparam H = 4;
    localparam FW = W * 4;
    localparam FH = H * 2;

    reg [$clog2(FH)-1:0] frame_ctr;
    reg [FW-1:0] frame_sr;

    always @(posedge cfg_frameinc, negedge cfg_mode)
        if (~cfg_mode)
            frame_ctr <= 0;
        else
            frame_ctr <= frame_ctr + 1'b1;

    always @(posedge cfg_dataclk)
        frame_sr <= {frame_sr[FW-2:0], cfg_data};

    wire [FH-1:0] frame_strb;
    wire gated_strobe = cfg_mode & cfg_framestrb;
    generate;
        genvar ii;
        for (ii = 0; ii < FH; ii = ii + 1'b1) begin
            //make sure this is glitch free
            sky130_fd_sc_hd__nand2_1 cfg_nand (.A(gated_strobe), .B(frame_ctr == ii), .Y(frame_strb[ii]));
        end
    endgenerate

    wire [0:W-1] cell_q[0:H-1];
    generate
        genvar xx;
        genvar yy;
        for (yy = 0; yy < H; yy = yy + 1'b1) begin: y_c
            for (xx = 0; xx < W; xx = xx + 1'b1) begin: x_c
                if (xx == (W - 1) && yy >= (H - 2)) begin // reduce area slightly
                    assign cell_q[yy][xx] = cell_q[yy][xx - 1];
                end else begin
                    wire ti, bi, li, ri;
                    if (yy > 0) assign ti = cell_q[yy-1][xx]; else assign ti = io_in[xx + 4];
                    if (yy < H-1) assign bi = cell_q[yy+1][xx]; else assign bi = cell_q[yy][xx];
                    if (xx > 0) assign li = cell_q[yy][xx-1]; else assign li = io_in[yy];
                    if (xx < W-1) assign ri = cell_q[yy][xx+1]; else assign ri = cell_q[yy][xx];
                    logic_cell_341404507891040852 lc_i (
                        .CLK(io_in[3]),
                        .cfg_strb(frame_strb[yy * 2 +: 2]),
                        .cfg_data(frame_sr[xx * 4 +: 4]),
                        .T(ti), .B(bi), .L(li),. R(ri),
                        .Q(cell_q[yy][xx])
                    );
                end
            end
        end
    endgenerate

    assign io_out = {cell_q[3][W-1], cell_q[2][W-1], cell_q[1][W-1], cell_q[0][W-1], cell_q[H-1][2], cell_q[H-1]};


endmodule

module logic_cell_341404507891040852 (
    input CLK,
    input [1:0] cfg_strb,
    input [3:0] cfg_data,
    input T, L, R, B,
    output Q
);

    // config storage
    wire [7:0] cfg;
    generate
    genvar ii, jj;
        for (ii = 0; ii < 2; ii = ii + 1'b1)
            for (jj = 0; jj < 4; jj = jj + 1'b1)
                sky130_fd_sc_hd__dlxtn_1 cfg_lat_i (
                    .D(cfg_data[jj]),
                    .GATE_N(cfg_strb[ii]),
                    .Q(cfg[ii*4 + jj])
                );
    endgenerate

    wire i0, i1;
    // I input muxes
    sky130_fd_sc_hd__mux4_1 i0mux (
        .A0(1'b0), .A1(T), .A2(R), .A3(L),
        .S0(cfg[0]), .S1(cfg[1]),
        .X(i0)
    );
    wire lb;
    sky130_fd_sc_hd__inv_1 linv (
        .A(L), .Y(lb)
    );
    sky130_fd_sc_hd__mux4_1 i1mux (
        .A0(1'b1), .A1(B), .A2(R), .A3(lb),
        .S0(cfg[2]), .S1(cfg[3]),
        .X(i1)
    );
    // S input mux
    wire s0s, s0;
    sky130_fd_sc_hd__mux4_1 smux (
        .A0(1'b0), .A1(T), .A2(R), .A3(L),
        .S0(cfg[4]), .S1(cfg[5]),
        .X(s0s)
    );
    // S invert
    sky130_fd_sc_hd__xnor2_1 sinv (
        .A(s0s), .B(cfg[6]), .Y(s0)
    );
    // The logic element
    wire muxo_n;
    sky130_fd_sc_hd__mux2i_1 lmux (
        .A0(i0), .A1(i1), .S(s0), .Y(muxo_n)
    );
    // The DFF
    wire dffo_n;
    sky130_fd_sc_hd__dfsbp_1 dff(
        .D(muxo_n),
        .SET_B(cfg_strb[0]),
        .CLK(CLK),
        .Q(dffo_n)
    );
    // The final output mux
    sky130_fd_sc_hd__mux2i_1 ffsel (
        .A0(muxo_n), .A1(dffo_n), .S(cfg[7]), .Y(Q)
    );
endmodule
