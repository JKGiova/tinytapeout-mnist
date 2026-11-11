`timescale 1ns / 1ps

module tb_uart_rx;

    reg clk = 0;
    reg rst_n = 0;
    reg rx = 1;
    wire byte_ready;
    wire [7:0] byte_out;

    reg [7:0] expected [0:49];
    reg previous_ready = 0;
    integer byte_count;
    integer received_count = 0;
    integer pause_cycles;
    integer i;
    integer j;

    uart_rx dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .byte_ready(byte_ready),
        .byte_out(byte_out)
    );

    always #5 clk = ~clk;

    always @(negedge clk) begin
        if (!rst_n) begin
            previous_ready = 0;
        end else begin
            if (byte_ready && previous_ready) begin
                $fatal(1, "byte_ready alto per piu di un ciclo");
            end

            if (byte_ready) begin
                if (received_count >= byte_count) begin
                    $fatal(1, "Byte inatteso: %h", byte_out);
                end
                if (byte_out !== expected[received_count]) begin
                    $fatal(1, "Byte %0d: atteso %h, ricevuto %h",
                           received_count, expected[received_count], byte_out);
                end
                $display("Byte %0d corretto: %h", received_count, byte_out);
                received_count = received_count + 1;
            end

            previous_ready = byte_ready;
        end
    end

    initial begin
        byte_count = $urandom_range(1, 50);

        for (i = 0; i < byte_count; i = i + 1) begin
            expected[i] = 8'($urandom_range(0, 255));
        end

        repeat (5) @(negedge clk);
        rst_n = 1;
        repeat (5) @(negedge clk);

        for (i = 0; i < byte_count; i = i + 1) begin
            rx = 0;
            repeat (1152) @(negedge clk);

            for (j = 0; j < 8; j = j + 1) begin
                rx = expected[i][j];
                repeat (1152) @(negedge clk);
            end

            rx = 1;
            repeat (1152) @(negedge clk);

            pause_cycles = $urandom_range(0, 2304);
            repeat (pause_cycles) @(negedge clk);
        end

        repeat (5) @(negedge clk);

        if (received_count != byte_count) begin
            $fatal(1, "Attesi %0d byte, ricevuti %0d", byte_count, received_count);
        end

        $display("Tutti i %0d byte sono stati ricevuti correttamente", byte_count);
        $finish;
    end

endmodule
