module ID_EXE_reg (
    input  wire        clk,
    input  wire        rst,

    input  wire        id_ready_go,
    input  wire        exe_allowin,

    input  wire        id_valid,
    input  wire [31:0] id_pc,
    input  wire [18:0] id_alu_op,
    input  wire [31:0] id_alu_src1,
    input  wire [31:0] id_alu_src2,
    input  wire [ 3:0] id_data_sram_we,
    input  wire [31:0] id_data_sram_wdata,
    input  wire        id_rf_we,
    input  wire [ 4:0] id_rf_waddr,
    input  wire        id_res_from_mem,

    output reg         exe_valid,
    output reg  [31:0] exe_pc,
    output reg  [18:0] exe_alu_op,
    output reg  [31:0] exe_alu_src1,
    output reg  [31:0] exe_alu_src2,
    output reg  [ 3:0] exe_data_sram_we,
    output reg  [31:0] exe_data_sram_wdata,
    output reg         exe_rf_we,
    output reg  [ 4:0] exe_rf_waddr,
    output reg         exe_res_from_mem
);

    always @(posedge clk) begin
        if (rst) begin
            exe_valid           <= 1'b0;
            exe_pc              <= 32'b0;
            exe_alu_op          <= 12'b0;
            exe_alu_src1        <= 32'b0;
            exe_alu_src2        <= 32'b0;
            exe_data_sram_we    <= 4'b0;
            exe_data_sram_wdata <= 32'b0;
            exe_rf_we           <= 1'b0;
            exe_rf_waddr        <= 5'b0;
            exe_res_from_mem    <= 1'b0;
        end
        else if (!exe_allowin) begin
            exe_valid           <= exe_valid;
            exe_pc              <= exe_pc;
            exe_alu_op          <= exe_alu_op;
            exe_alu_src1        <= exe_alu_src1;
            exe_alu_src2        <= exe_alu_src2;
            exe_data_sram_we    <= exe_data_sram_we;
            exe_data_sram_wdata <= exe_data_sram_wdata;
            exe_rf_we           <= exe_rf_we;
            exe_rf_waddr        <= exe_rf_waddr;
            exe_res_from_mem    <= exe_res_from_mem;
        end
        else if (!id_ready_go) begin
            exe_valid           <= 1'b0;
            exe_pc              <= 32'b0;
            exe_alu_op          <= 12'b0;
            exe_alu_src1        <= 32'b0;
            exe_alu_src2        <= 32'b0;
            exe_data_sram_we    <= 4'b0;
            exe_data_sram_wdata <= 32'b0;
            exe_rf_we           <= 1'b0;
            exe_rf_waddr        <= 5'b0;
            exe_res_from_mem    <= 1'b0;
        end
        else begin
            exe_valid           <= id_valid;
            exe_pc              <= id_pc;
            exe_alu_op          <= id_alu_op;
            exe_alu_src1        <= id_alu_src1;
            exe_alu_src2        <= id_alu_src2;
            exe_data_sram_we    <= id_data_sram_we;
            exe_data_sram_wdata <= id_data_sram_wdata;
            exe_rf_we           <= id_rf_we;
            exe_rf_waddr        <= id_rf_waddr;
            exe_res_from_mem    <= id_res_from_mem;
        end
    end

endmodule