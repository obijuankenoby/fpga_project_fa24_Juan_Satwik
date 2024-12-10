module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output [WIDTH-1:0] debounced_signal
);


    wire [1:0] sample_pulse_generator;
    reg [WRAPPING_CNT_WIDTH-1:0] wrapping_counter;
    
    initial begin
        wrapping_counter = 0;
    end

    always @(posedge clk) begin
        // Wrapping counter to generate sample pulse every SAMPLE_CNT_MAX cycles
        if (wrapping_counter == SAMPLE_CNT_MAX) begin
            wrapping_counter <= 0;
        end else begin
            wrapping_counter <= wrapping_counter + 1;
        end
    end

    //udpate sample_pulse here
    assign sample_pulse_generator = (wrapping_counter == SAMPLE_CNT_MAX);

    reg [SAT_CNT_WIDTH-1:0] saturating_counter [WIDTH-1:0];

    genvar  i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            always @(posedge clk ) begin
                if (sample_pulse_generator) begin
                    if(glitchy_signal[i]) begin
                       if (saturating_counter[i] < PULSE_CNT_MAX)
                        saturating_counter[i] <= saturating_counter[i] + 1;
                        else
                        saturating_counter[i] <= PULSE_CNT_MAX;
                    end
                    else 
                    saturating_counter[i] <= 0;
                end
            end
            assign debounced_signal[i] = (saturating_counter[i] >= PULSE_CNT_MAX);
        end
    endgenerate

endmodule