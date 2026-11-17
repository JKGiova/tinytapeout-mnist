module mac (
    input wire clk,
    input wire rst_n,
    input wire clear,
    input wire enable,
    input wire [7:0] pixel,
    input wire signed [3:0] weight,
    output reg signed [17:0] accumulator
);

    wire signed [8:0] pixel_signed;
    wire signed [12:0] product;

    assign pixel_signed = {1'd0, pixel};
    assign product = pixel_signed * weight;

    always @(posedge clk) begin
        if (!rst_n) begin
            accumulator <= 0;
        end else if (clear) begin
            accumulator <= 0;
        end else if (enable) begin
            accumulator <= accumulator + product;
        end
    end

endmodule
