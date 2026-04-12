module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3 :0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [3 :0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

    reg         reset;
    always @(posedge clk) reset <= ~resetn;

    reg         valid;
    always @(posedge clk) begin
        if (reset) begin
            valid <= 1'b0;
        end
        else begin
            valid <= 1'b1;
        end
    end

    wire if_valid;
    wire id_valid;
    wire exe_valid;
    wire mem_valid;
    wire wb_valid;

    wire if_ready_go;
    wire id_ready_go;
    wire exe_ready_go;
    wire mem_ready_go;
    wire wb_ready_go;

    wire id_allowin;
    wire exe_allowin;
    wire mem_allowin;
    wire wb_allowin;

    wire if_willgo;
    wire id_willgo;
    wire exe_willgo;
    wire mem_willgo;
    wire wb_willgo;

    // read after write
    wire id_block;
    wire id_need_rj;
    wire id_need_rk;
    wire id_need_rd;

    // forward
    wire [31:0] real_rj;
    wire [31:0] real_rk;
    wire [31:0] real_rd;

    wire exe_use_rj;
    wire exe_use_rk;
    wire exe_use_rd;
    wire mem_use_rj;
    wire mem_use_rk;
    wire mem_use_rd;
    wire wb_use_rj;
    wire wb_use_rk;
    wire wb_use_rd;

    wire exe_needforward_rj;
    wire exe_needforward_rk;
    wire exe_needforward_rd;
    wire mem_needforward_rj;
    wire mem_needforward_rk;
    wire mem_needforward_rd;
    wire wb_needforward_rj;
    wire wb_needforward_rk;
    wire wb_needforward_rd;

    // PC

    wire [31:0] pc;
    wire [31:0] seq_pc;
    wire [31:0] nextpc;

    // instruction fetch

    wire [31:0] inst;

    assign inst            = inst_sram_rdata;

    // -----------------

    wire [31:0] if_pc;
    wire [31:0] if_inst;
    wire [31:0] id_pc;
    wire [31:0] id_inst;

    assign if_pc           = pc;
    assign if_inst         = inst;

    IF_ID_reg if_id_reg(
        .clk         (clk        ),
        .rst         (reset      ),
        .if_ready_go (if_ready_go),
        .id_allowin  (id_allowin ),
        .if_valid    (if_valid   ),
        .if_pc       (if_pc      ),
        .if_inst     (if_inst    ),
        .id_valid    (id_valid   ),
        .id_pc       (id_pc      ),
        .id_inst     (id_inst    )
    );

    // instruction decode

    wire        br_taken;
    wire [31:0] br_target;

    wire [11:0] alu_op;
    wire        load_op;
    wire        src1_is_pc;
    wire        src2_is_imm;
    wire        res_from_mem;
    wire        dst_is_r1;
    wire        gr_we;
    wire        mem_we;
    wire        src_reg_is_rd;
    wire [4: 0] dest;
    wire [31:0] rj_value;
    wire [31:0] rkd_value;
    wire [31:0] imm;
    wire [31:0] br_offs;
    wire [31:0] jirl_offs;

    wire [ 5:0] op_31_26;
    wire [ 3:0] op_25_22;
    wire [ 1:0] op_21_20;
    wire [ 4:0] op_19_15;
    wire [63:0] op_31_26_d;
    wire [15:0] op_25_22_d;
    wire [ 3:0] op_21_20_d;
    wire [31:0] op_19_15_d;

    wire [ 4:0] rd;
    wire [ 4:0] rj;
    wire [ 4:0] rk;
    wire        rj_eq_rd;
    wire [11:0] i12;
    wire [19:0] i20;
    wire [15:0] i16;
    wire [25:0] i26;

    wire        inst_add_w;
    wire        inst_sub_w;
    wire        inst_slt;
    wire        inst_sltu;
    wire        inst_nor;
    wire        inst_and;
    wire        inst_or;
    wire        inst_xor;
    wire        inst_slli_w;
    wire        inst_srli_w;
    wire        inst_srai_w;
    wire        inst_addi_w;
    wire        inst_ld_w;
    wire        inst_st_w;
    wire        inst_jirl;
    wire        inst_b;
    wire        inst_bl;
    wire        inst_beq;
    wire        inst_bne;
    wire        inst_lu12i_w;

    wire        need_ui5;
    wire        need_si12;
    wire        need_si16;
    wire        need_si20;
    wire        need_si26;
    wire        src2_is_4;

    wire [ 4:0] rf_raddr1;
    wire [31:0] rf_rdata1;
    wire [ 4:0] rf_raddr2;
    wire [31:0] rf_rdata2;

    wire [31:0] alu_src1;
    wire [31:0] alu_src2;

    assign inst_sram_addr = nextpc;

    assign op_31_26       = id_inst[31:26];
    assign op_25_22       = id_inst[25:22];
    assign op_21_20       = id_inst[21:20];
    assign op_19_15       = id_inst[19:15];

    decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
    decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
    decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
    decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

    assign rd             = id_inst[ 4: 0];
    assign rj             = id_inst[ 9: 5];
    assign rk             = id_inst[14:10];

    assign i12            = id_inst[21:10];
    assign i20            = id_inst[24: 5];
    assign i16            = id_inst[25:10];
    assign i26            = {id_inst[ 9: 0], id_inst[25:10]};

    assign inst_add_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
    assign inst_sub_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
    assign inst_slt       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
    assign inst_sltu      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
    assign inst_nor       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
    assign inst_and       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
    assign inst_or        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
    assign inst_xor       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
    assign inst_slli_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
    assign inst_srli_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
    assign inst_srai_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
    assign inst_addi_w    = op_31_26_d[6'h00] & op_25_22_d[4'ha];
    assign inst_ld_w      = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
    assign inst_st_w      = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
    assign inst_jirl      = op_31_26_d[6'h13];
    assign inst_b         = op_31_26_d[6'h14];
    assign inst_bl        = op_31_26_d[6'h15];
    assign inst_beq       = op_31_26_d[6'h16];
    assign inst_bne       = op_31_26_d[6'h17];
    assign inst_lu12i_w   = op_31_26_d[6'h05] & ~id_inst[25];

    assign alu_op[ 0]     = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w | inst_jirl | inst_bl;
    assign alu_op[ 1]     = inst_sub_w;
    assign alu_op[ 2]     = inst_slt;
    assign alu_op[ 3]     = inst_sltu;
    assign alu_op[ 4]     = inst_and;
    assign alu_op[ 5]     = inst_nor;
    assign alu_op[ 6]     = inst_or;
    assign alu_op[ 7]     = inst_xor;
    assign alu_op[ 8]     = inst_slli_w;
    assign alu_op[ 9]     = inst_srli_w;
    assign alu_op[10]     = inst_srai_w;
    assign alu_op[11]     = inst_lu12i_w;

    assign need_ui5       = inst_slli_w | inst_srli_w | inst_srai_w;
    assign need_si12      = inst_addi_w | inst_ld_w | inst_st_w;
    assign need_si16      = inst_jirl | inst_beq | inst_bne;
    assign need_si20      = inst_lu12i_w;
    assign need_si26      = inst_b | inst_bl;
    assign src2_is_4      = inst_jirl | inst_bl;

    assign imm            = src2_is_4 ? 32'h4               :
                            need_si20 ? {i20[19:0], 12'b0}  :
                            {{20{i12[11]}}, i12[11:0]}      ;

    assign br_offs        = need_si26 ? {{4{i26[25]}}, i26[25:0], 2'b0} :
                            {{14{i16[15]}}, i16[15:0], 2'b0}            ;

    assign jirl_offs      = {{14{i16[15]}}, i16[15:0], 2'b0};

    assign src_reg_is_rd  = inst_beq | inst_bne | inst_st_w;

    assign src1_is_pc     = inst_jirl | inst_bl;

    assign src2_is_imm    = inst_slli_w |
                            inst_srli_w |
                            inst_srai_w |
                            inst_addi_w |
                            inst_ld_w   |
                            inst_st_w   |
                            inst_lu12i_w|
                            inst_jirl   |
                            inst_bl     ;

    assign res_from_mem   = inst_ld_w;
    assign dst_is_r1      = inst_bl;
    assign gr_we          = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b;
    assign mem_we         = inst_st_w;
    assign dest           = dst_is_r1 ? 5'd1 : rd;

    assign rf_raddr1      = rj;
    assign rf_raddr2      = src_reg_is_rd ? rd : rk;

    assign rj_value  = real_rj;
    assign rkd_value = src_reg_is_rd ? real_rd : real_rk;

    assign rj_eq_rd  = (rj_value == rkd_value);

    assign br_taken  = (  (inst_beq  &&  rj_eq_rd)
                       || (inst_bne  && !rj_eq_rd)
                       || inst_jirl
                       || inst_bl
                       || inst_b
                       ) && valid && id_valid && !id_block;
    assign br_target = (inst_beq || inst_bne || inst_bl || inst_b) ? (id_pc + br_offs) : (rj_value + jirl_offs);

    assign alu_src1  = src1_is_pc  ? id_pc[31:0] : rj_value;
    assign alu_src2  = src2_is_imm ? imm : rkd_value;

    // ------------------

    wire [11:0] id_alu_op;
    wire [31:0] id_alu_src1;
    wire [31:0] id_alu_src2;
    wire [ 3:0] id_data_sram_we;
    wire [31:0] id_data_sram_wdata;
    wire        id_rf_we;
    wire [ 4:0] id_rf_waddr;
    wire        id_res_from_mem;
    wire [31:0] exe_pc;
    wire [11:0] exe_alu_op;
    wire [31:0] exe_alu_src1;
    wire [31:0] exe_alu_src2;
    wire [ 3:0] exe_data_sram_we;
    wire [31:0] exe_data_sram_wdata;
    wire        exe_rf_we;
    wire [ 4:0] exe_rf_waddr;
    wire        exe_res_from_mem;

    assign id_alu_op          = alu_op;
    assign id_alu_src1        = alu_src1;
    assign id_alu_src2        = alu_src2;
    assign id_data_sram_we    = {4{mem_we && valid}};
    assign id_data_sram_wdata = rkd_value;
    assign id_rf_we           = gr_we && valid;
    assign id_rf_waddr        = dest;
    assign id_res_from_mem    = res_from_mem;

    ID_EXE_reg id_exe_reg(
        .clk                 (clk                ),
        .rst                 (reset              ),
        .id_ready_go         (id_ready_go        ),
        .exe_allowin         (exe_allowin        ),
        .id_valid            (id_valid           ),
        .id_pc               (id_pc              ),
        .id_alu_op           (id_alu_op          ),
        .id_alu_src1         (id_alu_src1        ),
        .id_alu_src2         (id_alu_src2        ),
        .id_data_sram_we     (id_data_sram_we    ),
        .id_data_sram_wdata  (id_data_sram_wdata ),
        .id_rf_we            (id_rf_we           ),
        .id_rf_waddr         (id_rf_waddr        ),
        .id_res_from_mem     (id_res_from_mem    ),
        .exe_valid           (exe_valid          ),
        .exe_pc              (exe_pc             ),
        .exe_alu_op          (exe_alu_op         ),
        .exe_alu_src1        (exe_alu_src1       ),
        .exe_alu_src2        (exe_alu_src2       ),
        .exe_data_sram_we    (exe_data_sram_we   ),
        .exe_data_sram_wdata (exe_data_sram_wdata),
        .exe_rf_we           (exe_rf_we          ),
        .exe_rf_waddr        (exe_rf_waddr       ),
        .exe_res_from_mem    (exe_res_from_mem   )
    );

    // execute

    wire [31:0] alu_result;

    alu u_alu(
        .alu_op     (exe_alu_op    ),
        .alu_src1   (exe_alu_src1  ),
        .alu_src2   (exe_alu_src2  ),
        .alu_result (alu_result)
    );

    assign data_sram_addr  = alu_result;
    assign data_sram_we    = exe_data_sram_we & {4{exe_valid}};
    assign data_sram_wdata = exe_data_sram_wdata;

    // -------

    wire [31:0] exe_alu_result;
    wire [31:0] mem_pc;
    wire [ 3:0] mem_data_sram_we;
    wire [31:0] mem_data_sram_wdata;
    wire        mem_rf_we;
    wire [ 4:0] mem_rf_waddr;
    wire        mem_res_from_mem;
    wire [31:0] mem_alu_result;

    assign exe_alu_result  = alu_result;

    EXE_MEM_reg exe_mem_reg(
        .clk                 (clk                ),
        .rst                 (reset              ),
        .exe_ready_go        (exe_ready_go       ),
        .mem_allowin         (mem_allowin        ),
        .exe_valid           (exe_valid          ),
        .exe_pc              (exe_pc             ),
        .exe_data_sram_we    (exe_data_sram_we   ),
        .exe_data_sram_wdata (exe_data_sram_wdata),
        .exe_rf_we           (exe_rf_we          ),
        .exe_rf_waddr        (exe_rf_waddr       ),
        .exe_res_from_mem    (exe_res_from_mem   ),
        .exe_alu_result      (exe_alu_result     ),
        .mem_valid           (mem_valid          ),
        .mem_pc              (mem_pc             ),
        .mem_data_sram_we    (mem_data_sram_we   ),
        .mem_data_sram_wdata (mem_data_sram_wdata),
        .mem_rf_we           (mem_rf_we          ),
        .mem_rf_waddr        (mem_rf_waddr       ),
        .mem_res_from_mem    (mem_res_from_mem   ),
        .mem_alu_result      (mem_alu_result     )
    );

    // memory access

    wire [31:0] mem_result;
    wire [31:0] final_result;

    assign mem_result      = data_sram_rdata;
    assign final_result    = mem_res_from_mem ? mem_result : mem_alu_result;

    // -------------

    wire [31:0] mem_rf_wdata;
    wire [31:0] wb_pc;
    wire        wb_rf_we;
    wire [ 4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;

    assign mem_rf_wdata    = final_result;

    MEM_WB_reg mem_wb_reg(
        .clk          (clk         ),
        .rst          (reset       ),
        .mem_ready_go (mem_ready_go),
        .wb_allowin   (wb_allowin  ),
        .mem_valid    (mem_valid   ),
        .mem_pc       (mem_pc      ),
        .mem_rf_we    (mem_rf_we   ),
        .mem_rf_waddr (mem_rf_waddr),
        .mem_rf_wdata (mem_rf_wdata),
        .wb_valid     (wb_valid    ),
        .wb_pc        (wb_pc       ),
        .wb_rf_we     (wb_rf_we    ),
        .wb_rf_waddr  (wb_rf_waddr ),
        .wb_rf_wdata  (wb_rf_wdata )
    );

    // write back

    wire        rf_we;
    wire [ 4:0] rf_waddr;
    wire [31:0] rf_wdata;

    assign rf_we     = wb_rf_we && wb_valid;
    assign rf_waddr  = wb_rf_waddr;
    assign rf_wdata  = wb_rf_wdata;

    // ----------

    assign if_valid     = !id_valid || !br_taken;

    assign if_ready_go  = if_valid;
    assign id_ready_go  = id_valid && !id_block;
    assign exe_ready_go = exe_valid;
    assign mem_ready_go = mem_valid;
    assign wb_ready_go  = wb_valid;

    assign id_allowin   = !id_valid || (id_ready_go && exe_allowin);
    assign exe_allowin  = !exe_valid || (exe_ready_go && mem_allowin);
    assign mem_allowin  = !mem_valid || (mem_ready_go && wb_allowin);
    assign wb_allowin   = 1'b1;

    assign if_willgo    = if_ready_go && id_allowin;
    assign id_willgo    = id_ready_go && exe_allowin;
    assign exe_willgo   = exe_ready_go && mem_allowin;
    assign mem_willgo   = mem_ready_go && wb_allowin;
    assign wb_willgo    = wb_ready_go;

    assign id_need_rj   = !inst_lu12i_w && !inst_b && !inst_bl && (rj != 5'b0);
    assign id_need_rk   = (inst_add_w || inst_sub_w || inst_slt || inst_sltu || inst_and || inst_or || inst_nor || inst_xor) && (rk != 5'b0);
    assign id_need_rd   = (inst_beq || inst_bne || inst_st_w) && (rd != 5'b0);

    assign exe_use_rj   = exe_valid && exe_rf_we && exe_rf_waddr == rj;
    assign exe_use_rk   = exe_valid && exe_rf_we && exe_rf_waddr == rk;
    assign exe_use_rd   = exe_valid && exe_rf_we && exe_rf_waddr == rd;
    assign mem_use_rj   = mem_valid && mem_rf_we && mem_rf_waddr == rj;
    assign mem_use_rk   = mem_valid && mem_rf_we && mem_rf_waddr == rk;
    assign mem_use_rd   = mem_valid && mem_rf_we && mem_rf_waddr == rd;
    assign wb_use_rj    = wb_valid  && wb_rf_we  && wb_rf_waddr  == rj;
    assign wb_use_rk    = wb_valid  && wb_rf_we  && wb_rf_waddr  == rk;
    assign wb_use_rd    = wb_valid  && wb_rf_we  && wb_rf_waddr  == rd;

    assign exe_needforward_rj = exe_use_rj && id_need_rj;
    assign exe_needforward_rk = exe_use_rk && id_need_rk;
    assign exe_needforward_rd = exe_use_rd && id_need_rd;
    assign mem_needforward_rj = mem_use_rj && id_need_rj;
    assign mem_needforward_rk = mem_use_rk && id_need_rk;
    assign mem_needforward_rd = mem_use_rd && id_need_rd;
    assign wb_needforward_rj  = wb_use_rj  && id_need_rj;
    assign wb_needforward_rk  = wb_use_rk  && id_need_rk;
    assign wb_needforward_rd  = wb_use_rd  && id_need_rd;

    assign real_rj = exe_needforward_rj ? exe_alu_result :
                     mem_needforward_rj ? mem_rf_wdata   :
                     wb_needforward_rj  ? wb_rf_wdata    :
                     rf_rdata1;

    assign real_rk = exe_needforward_rk ? exe_alu_result :
                     mem_needforward_rk ? mem_rf_wdata   :
                     wb_needforward_rk  ? wb_rf_wdata    :
                     rf_rdata2;

    assign real_rd = exe_needforward_rd ? exe_alu_result :
                     mem_needforward_rd ? mem_rf_wdata   :
                     wb_needforward_rd  ? wb_rf_wdata    :
                     rf_rdata2;

    assign id_block = (exe_needforward_rj || exe_needforward_rk || exe_needforward_rd) && exe_res_from_mem;

    PC_reg pc_reg(
        .clk    (clk   ),
        .rst    (reset ),
        .nextpc (nextpc),
        .pc     (pc    )
    );

    assign seq_pc = if_willgo ? pc + 32'h4 : pc;
    assign nextpc = br_taken ? br_target : seq_pc;

    regfile u_regfile(
        .clk    (clk      ),
        .raddr1 (rf_raddr1),
        .rdata1 (rf_rdata1),
        .raddr2 (rf_raddr2),
        .rdata2 (rf_rdata2),
        .we     (rf_we    ),
        .waddr  (rf_waddr ),
        .wdata  (rf_wdata )
    );

    assign inst_sram_en    = reset ? 1'b0 : 1'b1;
    assign inst_sram_we    = 4'b0;
    assign inst_sram_wdata = 32'b0;

    assign data_sram_en    = reset ? 1'b0 : 1'b1;

    // debug info generate
    assign debug_wb_pc       = wb_pc;
    assign debug_wb_rf_we    = {4{rf_we}};
    assign debug_wb_rf_wnum  = wb_rf_waddr;
    assign debug_wb_rf_wdata = wb_rf_wdata;

endmodule
