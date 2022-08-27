`default_nettype none

module pdm(
    input [4:0] pdm_input,
    input       write_en,
    input       clk, reset,    
    output      pdm_out
);

reg [4:0] accumulator;
reg [4:0] input_reg;

wire [5:0] sum;

assign sum = input_reg + accumulator;
assign pdm_out = sum[5];

always @(posedge clk or posedge reset) begin
    if (reset) begin 
        input_reg <= 5'h00 ;
        accumulator <= 5'h00;
    end else begin
        accumulator <= sum[4:0];
        if (write_en) input_reg <= pdm_input ;
    end
end

endmodule
