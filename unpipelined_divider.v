module unpipelined_divider #
(
    parameter N = 32
)
(
    input wire [N-1:0] dividend,
    input wire [N-1:0] divisor,
    input wire start,
    input wire rst,
    input wire clk,
    output reg [N-1:0] quotient,
    output reg [N-1:0] remainder,
    output reg done
);

    // Internal registers
    reg [N-1:0] quot_reg;        // Current quotient value
    reg [N:0] rem_reg;           // Current remainder value with extra bit
    reg [N-1:0] div_reg;         // Stored divisor
    reg [N-1:0] dividend_reg;    // Working copy of dividend
    reg [5:0] bit_counter;       // Counts which bit we're processing
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam INIT = 2'b01;
    localparam CALC = 2'b10;
    localparam FINISH = 2'b11;
    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers
            quot_reg <= 0;
            rem_reg <= 0;
            div_reg <= 0;
            dividend_reg <= 0;
            bit_counter <= 0;
            done <= 0;
            quotient <= 0;
            remainder <= 0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= INIT;
                    end
                end
                
                INIT: begin
                    // Initialize for division operation
                    quot_reg <= 0;
                    rem_reg <= 0;
                    div_reg <= divisor;
                    dividend_reg <= dividend;
                    bit_counter <= N;  // We'll count down to 0
                    state <= CALC;
                end
                
                CALC: begin
                    if (bit_counter > 0) begin
                        // Shift remainder left and bring in next bit of dividend
                        rem_reg <= {rem_reg[N-1:0], dividend_reg[N-1]};
                        dividend_reg <= {dividend_reg[N-2:0], 1'b0};  // Left shift dividend
                        
                        // Check if we can subtract
                        if ({rem_reg[N-1:0], dividend_reg[N-1]} >= {1'b0, div_reg}) begin
                            rem_reg <= {rem_reg[N-1:0], dividend_reg[N-1]} - {1'b0, div_reg};
                            quot_reg <= {quot_reg[N-2:0], 1'b1};  // Set current bit to 1
                        end else begin
                            quot_reg <= {quot_reg[N-2:0], 1'b0};  // Set current bit to 0
                        end
                        
                        bit_counter <= bit_counter - 1;
                    end else begin
                        state <= FINISH;
                    end
                end
                
                FINISH: begin
                    // Output results and set done flag
                    quotient <= quot_reg;
                    remainder <= rem_reg[N-1:0];
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule