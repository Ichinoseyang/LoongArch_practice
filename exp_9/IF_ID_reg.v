module IF_ID_reg (
    input  wire        clk,
    input  wire        rst,

    input  wire        if_ready_go,
    input  wire        id_allowin,

    input  wire        if_valid,
    input  wire [31:0] if_pc,
    input  wire [31:0] if_inst,

    output reg         id_valid,
    output reg  [31:0] id_pc,
    output reg  [31:0] id_inst
);
    
    always @(posedge clk) begin
        if (rst) begin
            id_valid <= 1'b0;
            id_pc    <= 32'h1bfffffc;
            id_inst  <= 32'h0;
        end
        else if (!id_allowin) begin
            id_valid <= id_valid;
            id_pc    <= id_pc;
            id_inst  <= id_inst;
        end
        else if (!if_ready_go) begin
            id_valid <= 1'b0;
            id_pc    <= 32'h1bfffffc;
            id_inst  <= 32'h0;
        end
        else begin
            id_valid <= if_valid;
            id_pc    <= if_pc;
            id_inst  <= if_inst;
        end
    end

endmodule