`timescale 1ns / 1ps

module tb_mac;

    reg clk;
    reg rst_n = 0;
    reg clear = 0;
    reg enable = 0;
    reg [7:0] pixel = 0;
    reg signed [3:0] weight = 0;
    wire signed [17:0] accumulator;
    integer i;

    mac dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight),
        .accumulator(accumulator)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        @(negedge clk);
        if (accumulator !== 18'sd0) begin
            $fatal(1, "Reset non riuscito: %0d", accumulator);
        end

        rst_n = 1;
        enable = 1;
        pixel = 8'd200;
        weight = -4'sd3;
        @(negedge clk);
        if (accumulator !== -18'sd600) begin
            $fatal(1, "Atteso -600, ricevuto %0d", accumulator);
        end

        pixel = 8'd10;
        weight = 4'sd2;
        @(negedge clk);
        if (accumulator !== -18'sd580) begin
            $fatal(1, "Atteso -580, ricevuto %0d", accumulator);
        end

        enable = 0;
        pixel = 8'd255;
        weight = 4'sd7;
        @(negedge clk);
        if (accumulator !== -18'sd580) begin
            $fatal(1, "Valore non mantenuto: %0d", accumulator);
        end

        clear = 1;
        enable = 1;
        @(negedge clk);
        if (accumulator !== 18'sd0) begin
            $fatal(1, "Clear non riuscito: %0d", accumulator);
        end

        clear = 0;
        for (i = 0; i < 49; i = i + 1) begin
            @(negedge clk);
        end
        if (accumulator !== 18'sd87465) begin
            $fatal(1, "Atteso 87465, ricevuto %0d", accumulator);
        end

        clear = 1;
        @(negedge clk);
        clear = 0;
        weight = -4'sd7;
        for (i = 0; i < 49; i = i + 1) begin
            @(negedge clk);
        end
        if (accumulator !== -18'sd87465) begin
            $fatal(1, "Atteso -87465, ricevuto %0d", accumulator);
        end

        rst_n = 0;
        @(negedge clk);
        if (accumulator !== 18'sd0) begin
            $fatal(1, "Reset durante il funzionamento non riuscito: %0d", accumulator);
        end

        $display("Tutti i controlli del MAC sono passati");
        $finish;
    end

endmodule
