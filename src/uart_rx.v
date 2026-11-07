module uart_rx (
    input wire clk, rst_n, rx,
    output reg [7:0] data_out,
    output reg data_ready
);

    reg [10:0] counter;
    reg [7:0] received_byte;
    reg [2:0] bit_index;
    reg [1:0] state;
    reg rx_sync_a, rx_sync_b;

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            data_ready <= 0;
            rx_sync_a <= 1;
            rx_sync_b <= 1;
            state <= IDLE;
            counter <= 11'd0;
            bit_index <= 3'd0;
            received_byte <= 8'd0;
            data_out <= 8'd0;

        end else begin 

            rx_sync_b <= rx_sync_a;
            rx_sync_a <= rx;
            data_ready <= 0;

            case (state)
                IDLE: begin 
                    if (rx_sync_b == 0) begin
                        state <= START;
                        counter <= 11'd0;
                    end
                end
                START: begin 
                    if (counter == 11'd575) begin
                        counter <= 11'd0;
                        if (rx_sync_b == 0) begin
                            state <= DATA;
                            bit_index <= 3'd0;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        counter <= counter + 11'd1;
                    end
                end
                DATA: begin 
                    if (counter == 11'd1151) begin
                        counter <= 11'd0;
                        received_byte[bit_index] <= rx_sync_b;
                        if (bit_index == 3'd7) begin 
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end else begin
                        counter <= counter + 11'd1;
                    end                    
                end
                STOP: begin 
                    if (counter == 11'd1151) begin
                        if (rx_sync_b == 1) begin
                            data_out <= received_byte;
                            data_ready <= 1;
                        end
                        state <= IDLE;
                    end else begin
                        counter <= counter + 11'd1;
                    end
                end
            endcase

        end

    end


endmodule
