`timescale 1ns / 1ps

module tb_uart_rx;
    localparam integer CYCLES_PER_BIT = 1152;

    reg clk = 0;
    reg rst_n = 0;
    reg rx = 1;
    wire [7:0] data_out;
    wire data_ready;
    integer received_count = 0;
    reg [7:0] expected [0:2];
    reg previous_ready = 0;

    uart_rx dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(data_out),
        .data_ready(data_ready)
    );

    // Un periodo comodo per la simulazione: conta il rapporto clock/baud.
    always #5 clk = ~clk;

    // Controlla l'impulso anche mentre il trasmettitore invia lo stop bit.
    always @(negedge clk) begin
        if (!rst_n) begin
            previous_ready = 0;
        end else begin
            if (data_ready && previous_ready)
                $fatal(1, "data_ready e' rimasto alto per piu' di un ciclo");
            if (data_ready) begin
                if (received_count >= 3)
                    $fatal(1, "Byte inatteso: %h", data_out);
                if (data_out !== expected[received_count])
                    $fatal(1, "Byte %0d: atteso %h, ricevuto %h",
                           received_count, expected[received_count], data_out);
                $display("OK: byte %0d ricevuto: %h", received_count, data_out);
                received_count = received_count + 1;
            end
            previous_ready = data_ready;
        end
    end

    task send_byte;
        input [7:0] value;
        input stop_bit;
        integer i;
        begin
            rx = 0;
            repeat (CYCLES_PER_BIT) @(negedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                rx = value[i];
                repeat (CYCLES_PER_BIT) @(negedge clk);
            end
            rx = stop_bit;
            repeat (CYCLES_PER_BIT) @(negedge clk);
        end
    endtask

    initial begin
        expected[0] = 8'h05;
        expected[1] = 8'ha5;
        expected[2] = 8'h00;

        repeat (5) @(negedge clk);
        rst_n = 1;
        repeat (5) @(negedge clk);

        // Un impulso piu' corto di mezzo bit non deve produrre un byte.
        rx = 0;
        repeat (100) @(negedge clk);
        rx = 1;
        repeat (CYCLES_PER_BIT) @(negedge clk);
        if (received_count != 0)
            $fatal(1, "Falso start accettato");

        // I tre byte arrivano consecutivamente, senza pause aggiuntive.
        send_byte(8'h05, 1);
        send_byte(8'ha5, 1);
        send_byte(8'h00, 1);
        if (received_count != 3)
            $fatal(1, "Attesi 3 byte, ricevuti %0d", received_count);

        // Stop basso: il byte deve essere scartato.
        send_byte(8'hff, 0);
        rx = 1;
        repeat (2 * CYCLES_PER_BIT) @(negedge clk);
        if (received_count != 3)
            $fatal(1, "Byte con stop non valido accettato");

        $display("Tutti i controlli UART sono passati.");
        $finish;
    end
endmodule
