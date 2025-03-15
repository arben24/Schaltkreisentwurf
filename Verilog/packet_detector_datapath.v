`timescale 1ns/1ps
module packet_detector_datapath(
    input clk,
    input rst,
    input start_i,
    
    input [15:0] r_i,
    input [15:0] i_i,
    
    input [2:0] mode_i,
    input wire check_for_packet_detect_i,
    
    // Register Transfer Inputs
    input wire r_i_to_ALU_a_i,
    input wire i_i_to_ALU_b_i,
    input wire mean_samples_to_ALU_i,
    input wire metrik_samples_to_ALU_R_i,
    input wire metrik_samples_to_ALU_I_i,
    input wire metrik_sum_R_to_ALU_a_i,
    input wire metrik_sum_I_to_ALU_b_i,
    input wire metrik_abs_to_ALU_A_i,
    input wire number_of_shifts_to_ALU_b_i,
    input wire payload_length_counter_to_ALU_a_i,
    input wire one_to_ALU_b_i,
    
    // Write Back Flags Inputs
    input wire wren_mean_abs_pow_i,
    input wire wren_mean_sum_i,
    input wire wren_metrik_sum_R_i,
    input wire wren_metrik_sum_I_i,
    input wire wren_metrik_abs_pow_i,
    input wire wren_metrik_shift_i,
    input wire wren_payload_length_counter_i,
    input wire wren_reset_payload_lenght_i,

    output signed [15:0] payload_length_o,
    output detect_o
);

    // Preamble-Konstanten (Q4.12)
    // Vorgabe (ursprüngliche Sequenz: [-1, 1, 1, 1, -1, -1, 1, -1, 1, 1, -1, -1, -1, -1, 1, 1, -1, 1, 1, -1, -1, -1, 1])
    // Neue Reihenfolge: P0 entspricht dem ersten Element (-1), P1 dem zweiten (+1), …, P22 dem letzten (+1)
localparam signed [15:0] P0  = 16'b0001000000000000;  // +1   (ehemals P22)
localparam signed [15:0] P1  = 16'b1111000000000000;  // -1   (ehemals P21)
localparam signed [15:0] P2  = 16'b1111000000000000;  // -1   (ehemals P20)
localparam signed [15:0] P3  = 16'b1111000000000000;  // -1   (ehemals P19)
localparam signed [15:0] P4  = 16'b0001000000000000;  // +1   (ehemals P18)
localparam signed [15:0] P5  = 16'b0001000000000000;  // +1   (ehemals P17)
localparam signed [15:0] P6  = 16'b1111000000000000;  // -1   (ehemals P16)
localparam signed [15:0] P7  = 16'b0001000000000000;  // +1   (ehemals P15)
localparam signed [15:0] P8  = 16'b0001000000000000;  // +1   (ehemals P14)
localparam signed [15:0] P9  = 16'b1111000000000000;  // -1   (ehemals P13)
localparam signed [15:0] P10 = 16'b1111000000000000;  // -1   (ehemals P12)
localparam signed [15:0] P11 = 16'b1111000000000000;  // -1   (ehemals P11)
localparam signed [15:0] P12 = 16'b1111000000000000;  // -1   (ehemals P10)
localparam signed [15:0] P13 = 16'b0001000000000000;  // +1   (ehemals P9)
localparam signed [15:0] P14 = 16'b0001000000000000;  // +1   (ehemals P8)
localparam signed [15:0] P15 = 16'b1111000000000000;  // -1   (ehemals P7)
localparam signed [15:0] P16 = 16'b0001000000000000;  // +1   (ehemals P6)
localparam signed [15:0] P17 = 16'b1111000000000000;  // -1   (ehemals P5)
localparam signed [15:0] P18 = 16'b1111000000000000;  // -1   (ehemals P4)
localparam signed [15:0] P19 = 16'b0001000000000000;  // +1   (ehemals P3)
localparam signed [15:0] P20 = 16'b0001000000000000;  // +1   (ehemals P2)
localparam signed [15:0] P21 = 16'b0001000000000000;  // +1   (ehemals P1)
localparam signed [15:0] P22 = 16'b1111000000000000;  // -1   (ehemals P0)

    // Temporäre Sample-Signale (Q4.12), die an die ALU weitergegeben werden
    reg signed [15:0] sample0_temp,  sample1_temp,  sample2_temp,  sample3_temp,  sample4_temp,  
                        sample5_temp,  sample6_temp,  sample7_temp,  sample8_temp,  sample9_temp,
                        sample10_temp, sample11_temp, sample12_temp, sample13_temp, sample14_temp,
                        sample15_temp, sample16_temp, sample17_temp, sample18_temp, sample19_temp,
                        sample20_temp, sample21_temp, sample22_temp;

    // Register zur Synchronisierung von r_i und i_i
    reg signed [15:0] r_temp, i_temp;
    reg signed [15:0] r_r, i_r;

    // Abs-Samples für die Metrikberechnung (Q4.12)
    reg signed [15:0] abs_sample0, abs_sample1, abs_sample2, abs_sample3, abs_sample4,
                       abs_sample5, abs_sample6, abs_sample7, abs_sample8, abs_sample9,
                       abs_sample10, abs_sample11, abs_sample12, abs_sample13, abs_sample14,
                       abs_sample15, abs_sample16, abs_sample17, abs_sample18, abs_sample19,
                       abs_sample20, abs_sample21, abs_sample22;

    // Term-Register (Ergebnis der bedingten Vorzeichenumkehr) – Q8.24-Erweiterung ist hier nicht erforderlich
reg signed [31:0]   term0_R, term0_I,term1_R, term1_I,term2_R, term2_I,term3_R, term3_I,
                    term4_R, term4_I,term5_R, term5_I,term6_R, term6_I,term7_R, term7_I,
                    term8_R, term8_I,term9_R, term9_I,term10_R, term10_I,term11_R, term11_I,
                    term12_R, term12_I,term13_R, term13_I,term14_R, term14_I,term15_R, term15_I,
                    term16_R, term16_I,term17_R, term17_I,term18_R, term18_I,term19_R, term19_I,
                    term20_R, term20_I,term21_R, term21_I,term22_R, term22_I;

// Shift-Register für r_i (für Metrikberechnung)
reg signed [15:0] r0, r1, r2, r3, r4, r5, r6, r7, r8, r9,
                  r10, r11, r12, r13, r14, r15, r16, r17, r18, r19,
                  r20, r21, r22;

// Shift-Register für i_i (für Metrikberechnung)
reg signed [15:0] i0, i1, i2, i3, i4, i5, i6, i7, i8, i9,
                  i10, i11, i12, i13, i14, i15, i16, i17, i18, i19,
                  i20, i21, i22;


    // Write Back Temp-Signale
    reg signed [15:0] mean_sum_temp;
    reg signed [15:0] metrik_sum_R_temp, metrik_sum_I_temp;
    reg signed [15:0] metrik_abs_pow_temp;
    reg signed [15:0] metrik_shift_temp;
    reg signed [15:0] payload_length_counter_temp;

    // Synchronized Write Back Register (falls benötigt)
    reg signed [15:0] metrik_sum_R_r, metrik_sum_I_r;
    reg signed [15:0] metrik_abs_pow_r;
    reg signed [15:0] metrik_shift_r;
    reg signed [15:0] mean_sum_r;
    reg signed [15:0] payload_length_counter_r;

    // ALU-Ergebnis (16 Bit)
    reg signed [15:0] alu_res_r;
    wire signed [15:0] alu_res;
    wire signed [15:0]  wbb;

// Instanziierung der ALU
packet_detector_alu packet_detector_alu_inst (
    .clk(clk),
    .rst(rst),
    .sample0_i(sample0_temp),
    .sample1_i(sample1_temp),
    .sample2_i(sample2_temp),
    .sample3_i(sample3_temp),
    .sample4_i(sample4_temp),
    .sample5_i(sample5_temp),
    .sample6_i(sample6_temp),
    .sample7_i(sample7_temp),
    .sample8_i(sample8_temp),
    .sample9_i(sample9_temp),
    .sample10_i(sample10_temp),
    .sample11_i(sample11_temp),
    .sample12_i(sample12_temp),
    .sample13_i(sample13_temp),
    .sample14_i(sample14_temp),
    .sample15_i(sample15_temp),
    .sample16_i(sample16_temp),
    .sample17_i(sample17_temp),
    .sample18_i(sample18_temp),
    .sample19_i(sample19_temp),
    .sample20_i(sample20_temp),
    .sample21_i(sample21_temp),
    .sample22_i(sample22_temp),
    .mode_i(mode_i),
    .res_o(alu_res)
);


    // Sequenzielle Logik
    always @(posedge clk) begin
        if (rst) begin
            r_r <= 16'd0;
            i_r <= 16'd0;
            r_temp <= 16'd0;
            i_temp <= 16'd0;
            alu_res_r <= 8'd0;

            metrik_sum_R_temp   <= 16'd0;
            metrik_sum_I_temp   <= 16'd0;
            metrik_abs_pow_temp <= 16'd0;
            metrik_shift_temp   <= 16'd0;
            payload_length_counter_temp <= 16'd0;

            // Reset der Abs-Sample-Register
            abs_sample0  <= 16'd0; abs_sample1  <= 16'd0; abs_sample2  <= 16'd0; abs_sample3  <= 16'd0; abs_sample4  <= 16'd0;
            abs_sample5  <= 16'd0; abs_sample6  <= 16'd0; abs_sample7  <= 16'd0; abs_sample8  <= 16'd0; abs_sample9  <= 16'd0;
            abs_sample10 <= 16'd0; abs_sample11 <= 16'd0; abs_sample12 <= 16'd0; abs_sample13 <= 16'd0; abs_sample14 <= 16'd0;
            abs_sample15 <= 16'd0; abs_sample16 <= 16'd0; abs_sample17 <= 16'd0; abs_sample18 <= 16'd0; abs_sample19 <= 16'd0;
            abs_sample20 <= 16'd0; abs_sample21 <= 16'd0; abs_sample22 <= 16'd0;
        end else begin
            // Synchronisiere r_i und i_i
            r_r <= r_temp;
            i_r <= i_temp;
            alu_res_r <= alu_res;

            // Write Back Temp-Signale
            mean_sum_r       <= mean_sum_temp;
            metrik_sum_R_r   <= metrik_sum_R_temp;
            metrik_sum_I_r   <= metrik_sum_I_temp;
            metrik_abs_pow_r <= metrik_abs_pow_temp;
            metrik_shift_r   <= metrik_shift_temp;
            payload_length_counter_r <= payload_length_counter_temp;

            if(start_i)begin

            r22 <= r21;
            r21 <= r20;
            r20 <= r19;
            r19 <= r18;
            r18 <= r17;
            r17 <= r16;
            r16 <= r15;
            r15 <= r14;
            r14 <= r13;
            r13 <= r12;
            r12 <= r11;
            r11 <= r10;
            r10 <= r9;
            r9  <= r8;
            r8  <= r7;
            r7  <= r6;
            r6  <= r5;
            r5  <= r4;
            r4  <= r3;
            r3  <= r2;
            r2  <= r1;
            r1  <= r0;
            r0  <= r_i;
            
            // Shift-Register für i_i für Metrikberechnung
            i22 <= i21;
            i21 <= i20;
            i20 <= i19;
            i19 <= i18;
            i18 <= i17;
            i17 <= i16;
            i16 <= i15;
            i15 <= i14;
            i14 <= i13;
            i13 <= i12;
            i12 <= i11;
            i11 <= i10;
            i10 <= i9;
            i9  <= i8;
            i8  <= i7;
            i7  <= i6;
            i6  <= i5;
            i5  <= i4;
            i4  <= i3;
            i3  <= i2;
            i2  <= i1;
            i1  <= i0;
            i0  <= i_i;

            end

        if(wren_mean_abs_pow_i) begin
            abs_sample22 <= abs_sample21;
            abs_sample21 <= abs_sample20;
            abs_sample20 <= abs_sample19;
            abs_sample19 <= abs_sample18;
            abs_sample18 <= abs_sample17;
            abs_sample17 <= abs_sample16;
            abs_sample16 <= abs_sample15;
            abs_sample15 <= abs_sample14;
            abs_sample14 <= abs_sample13;
            abs_sample13 <= abs_sample12;
            abs_sample12 <= abs_sample11;
            abs_sample11 <= abs_sample10;
            abs_sample10 <= abs_sample9;
            abs_sample9  <= abs_sample8;
            abs_sample8  <= abs_sample7;
            abs_sample7  <= abs_sample6;
            abs_sample6  <= abs_sample5;
            abs_sample5  <= abs_sample4;
            abs_sample4  <= abs_sample3;
            abs_sample3  <= abs_sample2;
            abs_sample2  <= abs_sample1;
            abs_sample1  <= abs_sample0;
            abs_sample0  <= wbb;
        end

        end
    end

    // Kombinatorische Logik
    always @(*) begin

        sample0_temp   = 'd0;
        sample1_temp   = 'd0;
        sample2_temp   = 'd0;
        sample3_temp   = 'd0;
        sample4_temp   = 'd0;
        sample5_temp   = 'd0;
        sample6_temp   = 'd0;
        sample7_temp   = 'd0;
        sample8_temp   = 'd0;
        sample9_temp   = 'd0;
        sample10_temp  = 'd0;
        sample11_temp  = 'd0;
        sample12_temp  = 'd0;
        sample13_temp  = 'd0;
        sample14_temp  = 'd0;
        sample15_temp  = 'd0;
        sample16_temp  = 'd0;
        sample17_temp  = 'd0;
        sample18_temp  = 'd0;
        sample19_temp  = 'd0;
        sample20_temp  = 'd0;
        sample21_temp  = 'd0;
        sample22_temp  = 'd0;
        mean_sum_temp = mean_sum_r;
        metrik_sum_R_temp   = metrik_sum_R_r;
        metrik_sum_I_temp   = metrik_sum_I_r;
        metrik_abs_pow_temp = metrik_abs_pow_r;
        metrik_shift_temp   = metrik_shift_r;
        payload_length_counter_temp = payload_length_counter_r;


        if (start_i) begin
            r_temp = r_i;
            i_temp = i_i;
        end

        // WRITE BACK 

        // Mean ABS POW: 

        if(wren_payload_length_counter_i) begin
            payload_length_counter_temp = wbb;
        end

        if(wren_mean_sum_i) begin
            mean_sum_temp = wbb;
        end
        //METRIK_SUM_WITH_MULT_I
        if(wren_metrik_sum_R_i) begin
            metrik_sum_R_temp = wbb;
        end
        //WB1
        if(wren_metrik_sum_I_i) begin
            metrik_sum_I_temp = wbb;
        end

        if(wren_metrik_abs_pow_i) begin
            metrik_abs_pow_temp = wbb;
        end

        if(wren_metrik_shift_i) begin
            metrik_shift_temp = wbb;
        end

        if(wren_reset_payload_lenght_i) begin
            payload_length_counter_temp = 16'b1111111111101001;
        end

        // REGISTER TRANSFER LOGIK

        // Übertrage r_i zu ALU-A 
        if (r_i_to_ALU_a_i) begin
            sample0_temp = r_r;
        end

        // Übertrage i_i zu ALU-B 
        if (i_i_to_ALU_b_i) begin
            sample1_temp = i_r;
        end
        // PAYLOAD_LENGTH_COUNTER
        if (payload_length_counter_to_ALU_a_i) begin
            sample0_temp = payload_length_counter_r;
        end
        if (one_to_ALU_b_i) begin
            sample1_temp = 16'd1;
        end


        // MEAN_SUM
        if (mean_samples_to_ALU_i) begin
            sample0_temp  = abs_sample0;
            sample1_temp  = abs_sample1;
            sample2_temp  = abs_sample2;
            sample3_temp  = abs_sample3;
            sample4_temp  = abs_sample4;
            sample5_temp  = abs_sample5;
            sample6_temp  = abs_sample6;
            sample7_temp  = abs_sample7;
            sample8_temp  = abs_sample8;
            sample9_temp  = abs_sample9;
            sample10_temp = abs_sample10;
            sample11_temp = abs_sample11;
            sample12_temp = abs_sample12;
            sample13_temp = abs_sample13;
            sample14_temp = abs_sample14;
            sample15_temp = abs_sample15;
            sample16_temp = abs_sample16;
            sample17_temp = abs_sample17;
            sample18_temp = abs_sample18;
            sample19_temp = abs_sample19;
            sample20_temp = abs_sample20;
            sample21_temp = abs_sample21;
            sample22_temp = abs_sample22;
        end
        // diese berechnung sollte nicht hier durchgeführt werden. Sollte besser in die Alu verschoben werden und da vielleicht als einzelner Modus eingeführt
        if (metrik_samples_to_ALU_R_i) begin
            term0_R  = (P0[15]  ? (~r0 + 1) : r0);
            term1_R  = (P1[15]  ? (~r1 + 1) : r1);
            term2_R  = (P2[15]  ? (~r2 + 1) : r2);
            term3_R  = (P3[15]  ? (~r3 + 1) : r3);
            term4_R  = (P4[15]  ? (~r4 + 1) : r4);
            term5_R  = (P5[15]  ? (~r5 + 1) : r5);
            term6_R  = (P6[15]  ? (~r6 + 1) : r6);
            term7_R  = (P7[15]  ? (~r7 + 1) : r7);
            term8_R  = (P8[15]  ? (~r8 + 1) : r8);
            term9_R  = (P9[15]  ? (~r9 + 1) : r9);
            term10_R = (P10[15] ? (~r10+ 1) : r10);
            term11_R = (P11[15] ? (~r11+ 1) : r11);
            term12_R = (P12[15] ? (~r12+ 1) : r12);
            term13_R = (P13[15] ? (~r13+ 1) : r13);
            term14_R = (P14[15] ? (~r14+ 1) : r14);
            term15_R = (P15[15] ? (~r15+ 1) : r15);
            term16_R = (P16[15] ? (~r16+ 1) : r16);
            term17_R = (P17[15] ? (~r17+ 1) : r17);
            term18_R = (P18[15] ? (~r18+ 1) : r18);
            term19_R = (P19[15] ? (~r19+ 1) : r19);
            term20_R = (P20[15] ? (~r20+ 1) : r20);
            term21_R = (P21[15] ? (~r21+ 1) : r21);
            term22_R = (P22[15] ? (~r22+ 1) : r22);
            
            sample0_temp  = term0_R;
            sample1_temp  = term1_R;
            sample2_temp  = term2_R;
            sample3_temp  = term3_R;
            sample4_temp  = term4_R;
            sample5_temp  = term5_R;
            sample6_temp  = term6_R;
            sample7_temp  = term7_R;
            sample8_temp  = term8_R;
            sample9_temp  = term9_R;
            sample10_temp = term10_R;
            sample11_temp = term11_R;
            sample12_temp = term12_R;
            sample13_temp = term13_R;
            sample14_temp = term14_R;
            sample15_temp = term15_R;
            sample16_temp = term16_R;
            sample17_temp = term17_R;
            sample18_temp = term18_R;
            sample19_temp = term19_R;
            sample20_temp = term20_R;
            sample21_temp = term21_R;
            sample22_temp = term22_R;
        end
        // diese berechnung sollte nicht hier durchgeführt werden. Sollte besser in die Alu verschoben werden und da vielleicht als einzelner Modus eingeführt
        if (metrik_samples_to_ALU_I_i) begin
            term0_I  = (P0[15]  ? (~i0 + 1) : i0);
            term1_I  = (P1[15]  ? (~i1 + 1) : i1);
            term2_I  = (P2[15]  ? (~i2 + 1) : i2);
            term3_I  = (P3[15]  ? (~i3 + 1) : i3);
            term4_I  = (P4[15]  ? (~i4 + 1) : i4);
            term5_I  = (P5[15]  ? (~i5 + 1) : i5);
            term6_I  = (P6[15]  ? (~i6 + 1) : i6);
            term7_I  = (P7[15]  ? (~i7 + 1) : i7);
            term8_I  = (P8[15]  ? (~i8 + 1) : i8);
            term9_I  = (P9[15]  ? (~i9 + 1) : i9);
            term10_I = (P10[15] ? (~i10+ 1) : i10);
            term11_I = (P11[15] ? (~i11+ 1) : i11);
            term12_I = (P12[15] ? (~i12+ 1) : i12);
            term13_I = (P13[15] ? (~i13+ 1) : i13);
            term14_I = (P14[15] ? (~i14+ 1) : i14);
            term15_I = (P15[15] ? (~i15+ 1) : i15);
            term16_I = (P16[15] ? (~i16+ 1) : i16);
            term17_I = (P17[15] ? (~i17+ 1) : i17);
            term18_I = (P18[15] ? (~i18+ 1) : i18);
            term19_I = (P19[15] ? (~i19+ 1) : i19);
            term20_I = (P20[15] ? (~i20+ 1) : i20);
            term21_I = (P21[15] ? (~i21+ 1) : i21);
            term22_I = (P22[15] ? (~i22+ 1) : i22);
            
            sample0_temp  = term0_I;
            sample1_temp  = term1_I;
            sample2_temp  = term2_I;
            sample3_temp  = term3_I;
            sample4_temp  = term4_I;
            sample5_temp  = term5_I;
            sample6_temp  = term6_I;
            sample7_temp  = term7_I;
            sample8_temp  = term8_I;
            sample9_temp  = term9_I;
            sample10_temp = term10_I;
            sample11_temp = term11_I;
            sample12_temp = term12_I;
            sample13_temp = term13_I;
            sample14_temp = term14_I;
            sample15_temp = term15_I;
            sample16_temp = term16_I;
            sample17_temp = term17_I;
            sample18_temp = term18_I;
            sample19_temp = term19_I;
            sample20_temp = term20_I;
            sample21_temp = term21_I;
            sample22_temp = term22_I;
        end

        // METRIK_ABS_POW
        if (metrik_sum_R_to_ALU_a_i) begin
            sample0_temp = metrik_sum_R_r; 
        end

        if (metrik_sum_I_to_ALU_b_i) begin
            sample1_temp = metrik_sum_I_r; 
        end

        // METRIK_SHIFT
        if (metrik_abs_to_ALU_A_i) begin
            sample0_temp = metrik_abs_pow_r; 
        end

        if (number_of_shifts_to_ALU_b_i) begin
            sample1_temp = 16'd4; 
        end
    end


    assign wbb = alu_res_r;
    assign detect_o = check_for_packet_detect_i && (metrik_shift_r > mean_sum_r);
    assign payload_length_o = (detect_o  ? payload_length_counter_r : 16'd0);

endmodule
