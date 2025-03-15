module packet_detector_controller(
    input clk,
    input rst,
    input start_i,
    input valid_i,
	input detect_o,
    output reg bussy_o,
    output reg [2:0] mode_o,
	output reg check_for_packet_detect_o,

    //register transfer
	output reg r_i_to_ALU_a_o,
	output reg i_i_to_ALU_b_o,
	output reg mean_samples_to_ALU_o,
	output reg metrik_samples_to_ALU_R_o,
	output reg metrik_samples_to_ALU_I_o,
	output reg metrik_sum_R_to_ALU_a_o,
	output reg metrik_sum_I_to_ALU_b_o,
	output reg metrik_abs_to_ALU_A_o,
	output reg number_of_shifts_to_ALU_b_o,
	output reg payload_length_counter_to_ALU_a_o,
	output reg one_to_ALU_b_o,

	//write back flags
	output reg wren_mean_abs_pow_o,
	output reg wren_mean_sum_o,
	output reg wren_metrik_sum_R_o,
	output reg wren_metrik_sum_I_o,
	output reg wren_metrik_abs_pow_o,
	output reg wren_metrik_shift_o,
	output reg wren_payload_length_counter_o,
	output reg wren_reset_payload_lenght_o
);

  // ALU Modes (3-Bit)
localparam SUM_23 		    = 3'd0;
localparam CMPLX_ABS_POW    = 3'd1;
localparam MULT 	        = 3'd2;
localparam SHIFT_RIGHT      = 3'd3;
localparam ALU_IDLE         = 3'd4;

  // FSM States (4-Bit, 11 Zustände)
localparam IDLE                    = 4'd0;
localparam MEAN_ABS_POW            = 4'd1;
localparam PAYLOAD_LENGTH_COUNTER  = 4'd2;
localparam MEAN_SUM                = 4'd3;
localparam METRIK_SUM_WITH_MULT_R  = 4'd4;
localparam METRIK_SUM_WITH_MULT_I  = 4'd5;
localparam WB1                     = 4'd6;
localparam METRIK_ABS_POW          = 4'd7;
localparam WB2                     = 4'd8;
localparam METRIK_SHIFT            = 4'd9;
localparam WB3                     = 4'd10;
localparam ENDIT                   = 4'd11;



  reg [3:0] current_state;
  reg [3:0] next_state;
  reg start_r;
  reg valid_r;


  always @(posedge clk) begin
    if(rst) begin
      valid_r       <= 1'b0;
      start_r       <= 1'b0;
      current_state <= IDLE;
    end else begin
      valid_r       <= valid_i;
      start_r       <= start_i;
      current_state <= next_state;
    end
  end


  always @(*) begin
    bussy_o                   = 1'b1;
    mode_o                    = ALU_IDLE;
    next_state                = current_state;
    check_for_packet_detect_o = 1'b0;
    
    // Register Transfer Signale
    r_i_to_ALU_a_o            = 1'b0;
    i_i_to_ALU_b_o            = 1'b0;
    mean_samples_to_ALU_o     = 1'b0;
    metrik_samples_to_ALU_R_o = 1'b0;
    metrik_samples_to_ALU_I_o = 1'b0;
    metrik_sum_R_to_ALU_a_o   = 1'b0;
    metrik_sum_I_to_ALU_b_o   = 1'b0;
    metrik_abs_to_ALU_A_o     = 1'b0;
    number_of_shifts_to_ALU_b_o = 1'b0;
    payload_length_counter_to_ALU_a_o = 1'b0;
    one_to_ALU_b_o = 1'b0;

    // Write Enable Signale
    wren_mean_abs_pow_o       = 1'b0;
    wren_mean_sum_o           = 1'b0;
    wren_metrik_sum_R_o       = 1'b0;
    wren_metrik_sum_I_o       = 1'b0;
    wren_metrik_abs_pow_o     = 1'b0;
    wren_metrik_shift_o       = 1'b0;
    wren_payload_length_counter_o = 1'b0;
    wren_reset_payload_lenght_o = 1'b0;
	
    
    case(current_state)
    
      IDLE: begin
        bussy_o = 1'b0;
        if(start_r == 1'b1) begin
          next_state = MEAN_ABS_POW;
        end
      end
      
      MEAN_ABS_POW: begin
        r_i_to_ALU_a_o = 1'b1;
        i_i_to_ALU_b_o = 1'b1;
        mode_o = CMPLX_ABS_POW;
        next_state = PAYLOAD_LENGTH_COUNTER;
      end

	  PAYLOAD_LENGTH_COUNTER: begin 
		wren_mean_abs_pow_o   = 1'b1;

		payload_length_counter_to_ALU_a_o = 1'b1;
		one_to_ALU_b_o = 1'b1;
		mode_o = SUM_23;

		next_state = MEAN_SUM;
	  end
      
      MEAN_SUM: begin  
		wren_payload_length_counter_o = 1'b1;  
        mean_samples_to_ALU_o = 1'b1;
        mode_o = SUM_23;
        next_state = METRIK_SUM_WITH_MULT_R;
      end
      
      METRIK_SUM_WITH_MULT_R: begin
        wren_mean_sum_o              = 1'b1;
        metrik_samples_to_ALU_R_o    = 1'b1;
        mode_o = SUM_23;
        next_state = METRIK_SUM_WITH_MULT_I;
      end
      
      METRIK_SUM_WITH_MULT_I: begin
        wren_metrik_sum_R_o          = 1'b1;
        metrik_samples_to_ALU_I_o    = 1'b1;
        mode_o = SUM_23;
        next_state = WB1;
      end
      
      WB1: begin
        wren_metrik_sum_I_o = 1'b1;
        next_state = METRIK_ABS_POW;
      end
      
      METRIK_ABS_POW: begin
        metrik_sum_R_to_ALU_a_o = 1'b1;
        metrik_sum_I_to_ALU_b_o = 1'b1;
        mode_o = CMPLX_ABS_POW;
        next_state = WB2;
      end
      
      WB2: begin
        wren_metrik_abs_pow_o = 1'b1;
        next_state = METRIK_SHIFT;
      end
      
      METRIK_SHIFT: begin
        metrik_abs_to_ALU_A_o      = 1'b1;
        number_of_shifts_to_ALU_b_o= 1'b1;
        mode_o = SHIFT_RIGHT;
        next_state = WB3;
      end
      
      WB3: begin
        wren_metrik_shift_o = 1'b1;
        next_state = ENDIT;
      end
      
      ENDIT: begin
        check_for_packet_detect_o = 1'b1;
		if (detect_o)begin

			wren_reset_payload_lenght_o = 1'b1;

		end

        next_state = IDLE;
      end
      
      default: begin
        next_state = IDLE;
      end
      
    endcase
  end

endmodule
