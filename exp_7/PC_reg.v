module PC_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] nextpc,
    output reg  [31:0] pc
);

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'h1bfffffc;
        end
        else begin
            pc <= nextpc;
        end
    end

endmodule