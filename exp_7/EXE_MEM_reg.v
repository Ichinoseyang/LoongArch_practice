module EXE_MEM_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] exe_pc,
    input  wire [ 3:0] exe_data_sram_we,
    input  wire [31:0] exe_data_sram_wdata,
    input  wire        exe_rf_we,
    input  wire [ 4:0] exe_rf_waddr,
    input  wire        exe_res_from_mem,
    input  wire [31:0] exe_alu_result,

    output reg  [31:0] mem_pc,
    output reg  [ 3:0] mem_data_sram_we,
    output reg  [31:0] mem_data_sram_wdata,
    output reg         mem_rf_we,
    output reg  [ 4:0] mem_rf_waddr,
    output reg         mem_res_from_mem,
    output reg  [31:0] mem_alu_result
);

    always @(posedge clk) begin
        if (rst) begin
            mem_pc              <= 32'b0;
            mem_data_sram_we    <=  4'b0;
            mem_data_sram_wdata <= 32'b0;
            mem_rf_we           <=  1'b0;
            mem_rf_waddr        <=  5'b0;
            mem_res_from_mem    <=  1'b0;
            mem_alu_result      <= 32'b0;
        end
        else begin
            mem_pc              <= exe_pc;
            mem_data_sram_we    <= exe_data_sram_we;
            mem_data_sram_wdata <= exe_data_sram_wdata;
            mem_rf_we           <= exe_rf_we;
            mem_rf_waddr        <= exe_rf_waddr;
            mem_res_from_mem    <= exe_res_from_mem;
            mem_alu_result      <= exe_alu_result;
        end
    end

endmodule