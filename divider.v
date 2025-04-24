module divider #
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
    reg [N:0] remainder_reg [0:N]; 
    reg [N-1:0] divisor_reg [0:N];
    reg [N-1:0] quotient_reg [0:N];
    reg [N-1:0] dividend_reg [0:N];
    reg ready_flag [0:N];

    integer i;
    reg [N:0] candidate;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            for (i = 0; i <= N; i = i + 1) begin
                remainder_reg[i] <= 0;
                divisor_reg[i] <= 0;
                quotient_reg[i] <= 0;
                ready_flag[i] <= 0;
                dividend_reg[i] <= 0;
            end
            done <= 0;
        end
        else begin
            remainder_reg[0] <= 0;
            divisor_reg[0] <= divisor;
            quotient_reg[0] <= 0;
            ready_flag[0] <= start;
            dividend_reg[0] <= dividend;

            for (i = 0; i < N; i = i + 1) begin
                if (ready_flag[i]) begin
                    candidate = {remainder_reg[i][N-1:0], dividend_reg[i][N-1]};
                    dividend_reg[i+1] <= dividend_reg[i] << 1;
                    if (candidate < {1'b0, divisor_reg[i]}) begin
                        quotient_reg[i+1] <= (quotient_reg[i] << 1);
                        remainder_reg[i+1] <= candidate;
                    end 
                    else begin
                        quotient_reg[i+1] <= (quotient_reg[i] << 1) | 1'b1;
                        remainder_reg[i+1] <= candidate - {1'b0, divisor_reg[i]};
                    end
                    divisor_reg[i+1] <= divisor_reg[i];
                    ready_flag[i+1] <= ready_flag[i];
                end
                else begin
                    dividend_reg[i+1]  <= dividend_reg[i];
                    quotient_reg[i+1]  <= quotient_reg[i];
                    remainder_reg[i+1] <= remainder_reg[i];
                    divisor_reg[i+1]   <= divisor_reg[i];
                    ready_flag[i+1]     <= ready_flag[i];
                end
            end

            if (ready_flag[N]) begin
                quotient <= quotient_reg[N];
                remainder <= remainder_reg[N][N-1:0];
                done <= 1;
            end 
            else begin
                done <= 0;
            end
        end
    end
endmodule