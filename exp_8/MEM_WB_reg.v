module MEM_WB_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] mem_pc,
    input  wire        mem_rf_we,
    input  wire [ 4:0] mem_rf_waddr,
    input  wire [31:0] mem_rf_wdata,

    output reg  [31:0] wb_pc,
    output reg         wb_rf_we,
    output reg  [ 4:0] wb_rf_waddr,
    output reg  [31:0] wb_rf_wdata
);

    always @(posedge clk) begin
        if (rst) begin
            wb_pc       <= 32'b0;
            wb_rf_we    <=  1'b0;
            wb_rf_waddr <=  5'b0;
            wb_rf_wdata <= 32'b0;
        end
        else begin
            wb_pc       <= mem_pc;
            wb_rf_we    <= mem_rf_we;
            wb_rf_waddr <= mem_rf_waddr;
            wb_rf_wdata <= mem_rf_wdata;
        end
    end

endmodule