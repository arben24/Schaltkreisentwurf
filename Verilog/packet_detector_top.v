module packet_detector_top(
    input         rst,       // Active high rst
    input         Clk,         // System Clock
    input         start_i,     // Start Signal
    input         valid_i,     // Valid Signal (z. B. für Testdaten)
    input  signed [15:0] r_i,  //  Realteil (Q4.12)
    input  signed [15:0] i_i,  //  Imaginärteil (Q4.12)
    output signed [15:0] payload_length,
    output wire detect_o       
);

  
    wire [2:0] alu_mode;     
    wire bussy;               r
    wire check_for_packet_detect; 

    // Register Transfer Signale 
    wire r_i_to_ALU_a;
    wire i_i_to_ALU_b;
    wire mean_samples_to_ALU;
    wire metrik_samples_to_ALU_R;
    wire metrik_samples_to_ALU_I;
    wire metrik_sum_R_to_ALU_a;
    wire metrik_sum_I_to_ALU_b;
    wire metrik_abs_to_ALU_A;
    wire number_of_shifts_to_ALU_b;
    wire payload_length_counter_to_ALU_a;
    wire one_to_ALU_b;

    // Write Back Flag Signale
    wire wren_mean_abs_pow;
    wire wren_mean_sum;
    wire wren_metrik_sum_R;
    wire wren_metrik_sum_I;
    wire wren_metrik_abs_pow;
    wire wren_metrik_shift;
    wire wren_reset_payload_lenght;
    wire wren_payload_length_counter;

    // Instanziere des DATAPATH
 packet_detector_datapath DATAPATH (
         .clk(Clk),
         .rst(rst),
         .start_i(start_i),
         .r_i(r_i),
         .i_i(i_i),
         .mode_i(alu_mode),
         .check_for_packet_detect_i(check_for_packet_detect),
         // Register Transfer Inputs (vom Controller)
         .r_i_to_ALU_a_i(r_i_to_ALU_a),
         .i_i_to_ALU_b_i(i_i_to_ALU_b),
         .mean_samples_to_ALU_i(mean_samples_to_ALU),
         .metrik_samples_to_ALU_R_i(metrik_samples_to_ALU_R),
         .metrik_samples_to_ALU_I_i(metrik_samples_to_ALU_I),
         .metrik_sum_R_to_ALU_a_i(metrik_sum_R_to_ALU_a),
         .metrik_sum_I_to_ALU_b_i(metrik_sum_I_to_ALU_b),
         .metrik_abs_to_ALU_A_i(metrik_abs_to_ALU_A),
         .number_of_shifts_to_ALU_b_i(number_of_shifts_to_ALU_b),
        .payload_length_counter_to_ALU_a_i(payload_length_counter_to_ALU_a),
         .one_to_ALU_b_i(one_to_ALU_b),
         // Write Back Flag Inputs (vom Controller)
         .wren_mean_abs_pow_i(wren_mean_abs_pow),
         .wren_mean_sum_i(wren_mean_sum),
         .wren_metrik_sum_R_i(wren_metrik_sum_R),
         .wren_metrik_sum_I_i(wren_metrik_sum_I),
         .wren_metrik_abs_pow_i(wren_metrik_abs_pow),
         .wren_metrik_shift_i(wren_metrik_shift),
         .wren_payload_length_counter_i(wren_payload_length_counter),
         .wren_reset_payload_lenght_i(wren_reset_payload_lenght),
         // Datapath Outputs
         .payload_length_o(payload_length),
         .detect_o(detect_o)
    );


    // Instanziere des Controllers
    packet_detector_controller CONTROLLER (
         .clk(Clk),
         .rst(rst),
         .start_i(start_i),
         .valid_i(valid_i),
         .detect_o(detect_o),
         .bussy_o(bussy),
         .mode_o(alu_mode),
         .check_for_packet_detect_o(check_for_packet_detect),
         // Register Transfer Outputs
         .r_i_to_ALU_a_o(r_i_to_ALU_a),
         .i_i_to_ALU_b_o(i_i_to_ALU_b),
         .mean_samples_to_ALU_o(mean_samples_to_ALU),
         .metrik_samples_to_ALU_R_o(metrik_samples_to_ALU_R),
         .metrik_samples_to_ALU_I_o(metrik_samples_to_ALU_I),
         .metrik_sum_R_to_ALU_a_o(metrik_sum_R_to_ALU_a),
         .metrik_sum_I_to_ALU_b_o(metrik_sum_I_to_ALU_b),
         .metrik_abs_to_ALU_A_o(metrik_abs_to_ALU_A),
         .number_of_shifts_to_ALU_b_o(number_of_shifts_to_ALU_b),
         .payload_length_counter_to_ALU_a_o(payload_length_counter_to_ALU_a),
         .one_to_ALU_b_o(one_to_ALU_b),
         // Write Back Outputs
         .wren_mean_abs_pow_o(wren_mean_abs_pow),
         .wren_mean_sum_o(wren_mean_sum),
         .wren_metrik_sum_R_o(wren_metrik_sum_R),
         .wren_metrik_sum_I_o(wren_metrik_sum_I),
         .wren_metrik_abs_pow_o(wren_metrik_abs_pow),
         .wren_metrik_shift_o(wren_metrik_shift),
         .wren_payload_length_counter_o(wren_payload_length_counter),
         .wren_reset_payload_lenght_o(wren_reset_payload_lenght)
    );


endmodule