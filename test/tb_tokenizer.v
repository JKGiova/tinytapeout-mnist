`timescale 1ns / 1ps

module tb_tokenizer;

    reg clk;
    reg rst_n = 0;
    reg byte_ready = 0;
    reg [7:0] byte_in = 0;
    reg [5:0] indexer = 0;
    wire image_vector_ready;
    wire pixel_ready;
    wire [7:0] pixel_out;
    integer i;

    tokenizer dut (
        .clk(clk),
        .rst_n(rst_n),
        .byte_ready(byte_ready),
        .byte_in(byte_in),
        .indexer(indexer),
        .image_vector_ready(image_vector_ready),
        .pixel_ready(pixel_ready),
        .pixel_out(pixel_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        repeat (2) @(negedge clk);
        if (image_vector_ready !== 0 || pixel_ready !== 0) begin
            $fatal(1, "Reset non riuscito");
        end
        rst_n = 1;

        for (i = 0; i < 49; i = i + 1) begin
            byte_in = 8'(i * 5 + 3);
            byte_ready = 1;
            @(negedge clk);
            byte_ready = 0;
            if (i < 48 && (image_vector_ready !== 0 || pixel_ready !== 0)) begin
                $fatal(1, "Immagine pronta prima del pixel 49");
            end
            @(negedge clk);
        end

        if (image_vector_ready !== 1) begin
            $fatal(1, "Immagine non pronta dopo 49 pixel");
        end

        for (i = 0; i < 49; i = i + 1) begin
            indexer = 6'(i);
            #1;
            if (pixel_ready !== 1 || pixel_out !== 8'(i * 5 + 3)) begin
                $fatal(1, "Pixel %0d: atteso %0d, ricevuto %0d", i, i * 5 + 3, pixel_out);
            end
        end

        for (i = 49; i < 64; i = i + 1) begin
            indexer = 6'(i);
            #1;
            if (pixel_ready !== 0) begin
                $fatal(1, "Indice non valido %0d accettato", i);
            end
        end

        @(negedge clk);
        byte_in = 255;
        byte_ready = 1;
        @(negedge clk);
        byte_ready = 0;
        indexer = 0;
        #1;
        if (image_vector_ready !== 1 || pixel_ready !== 1 || pixel_out !== 3) begin
            $fatal(1, "Un byte aggiuntivo ha modificato l'immagine");
        end

        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        if (image_vector_ready !== 0 || pixel_ready !== 0) begin
            $fatal(1, "Reset dopo il caricamento non riuscito");
        end

        $display("Tutti i controlli del tokenizer sono passati");
        $finish;
    end

endmodule
