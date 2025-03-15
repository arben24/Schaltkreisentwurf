// alu
module packet_detector_alu(
    input clk,
    input rst,
    input signed [15:0] sample0_i, sample1_i, sample2_i, sample3_i, sample4_i,    // sample0, sample1 haben mehrere Funktionen
                        sample5_i, sample6_i, sample7_i, sample8_i, sample9_i,
                        sample10_i, sample11_i, sample12_i, sample13_i, sample14_i,
                        sample15_i, sample16_i, sample17_i, sample18_i, sample19_i,
                        sample20_i, sample21_i, sample22_i,
    input [2:0] mode_i,
    output reg [15:0] res_o
);

reg [31:0] mult_result;
reg [15:0] abs_r, abs_i;

// Rechenoperationen
localparam SUM_23         = 3'd0;
localparam CMPLX_ABS_POW  = 3'd1;
localparam MULT           = 3'd2;
localparam SHIFT_RIGHT    = 3'd3;
localparam ALU_IDLE       = 3'd4;

always @(*) begin
    case(mode_i)
        SUM_23: begin
            res_o = sample0_i + sample1_i + sample2_i + sample3_i + sample4_i + 
                    sample5_i + sample6_i + sample7_i + sample8_i + sample9_i + 
                    sample10_i + sample11_i + sample12_i + sample13_i + sample14_i + 
                    sample15_i + sample16_i + sample17_i + sample18_i + sample19_i + 
                    sample20_i + sample21_i + sample22_i;
        end
        
        CMPLX_ABS_POW: begin
            abs_r = (sample0_i[15] == 1'b1) ? (~sample0_i + 16'd1) : sample0_i;
            abs_i = (sample1_i[15] == 1'b1) ? (~sample1_i + 16'd1) : sample1_i;
      
            mult_result = (abs_r * abs_r) + (abs_i * abs_i);                 
            res_o = mult_result >>> 12;
        end

        MULT: begin
            mult_result = sample0_i * sample1_i;
            res_o = mult_result >>> 12;
        end

        SHIFT_RIGHT: begin
            res_o = sample0_i >>> 4;
        end

        default: res_o = 16'd0;
    endcase
end

endmodule
