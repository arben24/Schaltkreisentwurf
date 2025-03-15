`timescale 1ns / 1ps

module packet_detector_top_tb;

    // Testbench-Signale
    reg         clk;
    reg         rst;
    reg         start_i;
    reg         valid_i;
    reg signed [15:0] r_i;
    reg signed [15:0] i_i;
    wire        detect_o;
    wire signed [15:0] payload_length;
    
    integer inputfile_fd, count,sample_counter;

        // Instanziierung des Top-Moduls
    packet_detector_top uut (
        .rst( rst ),
        .Clk( clk ),
        .start_i( start_i ),
        .valid_i( valid_i ),
        .r_i( r_i ),
        .i_i( i_i ),
        .payload_length(payload_length),
        .detect_o( detect_o )
    );
    
    // Basistakt-Generierung: 16 MHz (Period = 62.5 ns)
    initial begin
        clk = 0;
        forever #31.25 clk = ~clk; // 31.25 ns high, 31.25 ns low
    end
    
    // Reset-Initialisierung
    initial begin
        rst = 1;
        #200;  // Reset für ca. 200 ns aktiv
        rst = 0;
    end
    

    initial begin
        inputfile_fd = $fopen("test_signal.txt", "r");
        if (inputfile_fd == 0) begin
            $display("Fehler: Datei test_signal.txt konnte nicht geöffnet werden.");
            $finish;
        end
        
        // Warte, bis Reset beendet ist
        #250;
        count = 0;
        sample_counter = 0;
        start_i = 0;
        valid_i = 0;
        
        while (!$feof(inputfile_fd)) begin
            @(posedge clk);
            sample_counter = sample_counter + 1;
            if (sample_counter == 16) begin
                sample_counter = 0;
                if ($fscanf(inputfile_fd, "%b, %b\n", r_i, i_i) != 2) begin
                    $display("Fehler beim Lesen der Eingabedaten.");
                    $finish;
                end
                count = count + 1;
                // Für einen Takt high: setze start_i und valid_i high
                start_i = 1;
                valid_i = 1;
                //$display("Count = %0d, t = %0t, r_i = %b, i_i = %b, detect_o = %b", count, $time, r_i, i_i, detect_o);
            end
            else begin
                start_i = 0;
                valid_i = 0;
                if(detect_o)begin

                  $display("DETECT BEI: Count = %0d, payload_length = %0d, r_i = %b, i_i = %b, detect_o = %b", 
                         count, payload_length, r_i, i_i, detect_o);  

                end
            end
        end
        
        $display("Total number of samples read: %0d", count);
        $fclose(inputfile_fd);
        #200;
        $stop;
    end

endmodule
