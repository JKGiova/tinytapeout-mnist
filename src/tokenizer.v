module tokenizer (
    input wire clk,
    input wire rst_n,
    input wire byte_ready,
    input wire [7:0] byte_in,
    input wire [5:0] indexer,
    output reg image_vector_ready,
    output reg pixel_ready,
    output reg [7:0] pixel_out
);

    reg [7:0] image_vector [48:0];
    reg [5:0] writing_counter;
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            image_vector_ready <= 0;
            writing_counter <= 0;
            for (i = 0; i < 49; i = i + 1) begin
                image_vector [i] <= 0;
            end
        end else if (byte_ready && !image_vector_ready) begin
            image_vector [writing_counter] <= byte_in;
            if (writing_counter < 48)
                writing_counter <= writing_counter + 1;
            else begin
                writing_counter <= 0;
                image_vector_ready <= 1;
            end
        end
    end

    always @(*) begin
        if (!rst_n) begin
            pixel_ready = 0;
            pixel_out = 0;
        end else if (indexer <= 48 && image_vector_ready) begin
            pixel_ready = 1;
            pixel_out = image_vector [indexer];
        end else begin
            pixel_ready = 0;
            pixel_out = 0;
        end
    end

endmodule