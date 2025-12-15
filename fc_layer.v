
 module fc_layer #(
    parameter DATA_WIDTH  = 8,
    parameter ACC_WIDTH   = 24,
    parameter NUM_NEURONS = 10, 
    parameter NUM_INPUTS  = 4
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [DATA_WIDTH-1:0] data_in,
    
    output reg signed [DATA_WIDTH-1:0] data_out,
    output reg out_valid,
    output reg done,
    output reg input_req
);

    localparam TOTAL_WEIGHTS = NUM_NEURONS * NUM_INPUTS;

    reg signed [DATA_WIDTH-1:0] mem_weights [0:TOTAL_WEIGHTS-1];
    reg signed [DATA_WIDTH-1:0] mem_biases  [0:NUM_NEURONS-1];

    initial begin
        $readmemh("weights.hex", mem_weights);
        $readmemh("biases.hex", mem_biases);
    end

    reg [3:0] neuron_pair_cnt;
    reg [3:0] input_cnt;
    
    reg signed [ACC_WIDTH-1:0] acc0, acc1;
    
    reg signed [15:0] prod0_reg, prod1_reg;

    localparam IDLE       = 0;
    localparam REQ_DATA   = 1;
    localparam WAIT_DATA  = 2;
    localparam CHECK_ZERO = 3; 
    localparam STAGE_MULT = 4;
    localparam STAGE_ACC  = 5;
    localparam BIAS       = 6;
    localparam OUT_0      = 7;
    localparam OUT_1      = 8;
    localparam DONE       = 9;
    
    reg [3:0] state;

    wire [7:0] w_addr_0 = (neuron_pair_cnt * NUM_INPUTS) + input_cnt;
    wire [7:0] w_addr_1 = ((neuron_pair_cnt + 1) * NUM_INPUTS) + input_cnt;

    function [DATA_WIDTH-1:0] activate;
        input signed [ACC_WIDTH-1:0] val;
        begin
            if (val < 0) 
                activate = {DATA_WIDTH{1'b0}};
            else if (val > {1'b0, {(DATA_WIDTH-1){1'b1}}}) 
                activate = {1'b0, {(DATA_WIDTH-1){1'b1}}}; 
            else 
                activate = val[DATA_WIDTH-1:0];
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            acc0 <= 0; acc1 <= 0;
            prod0_reg <= 0; prod1_reg <= 0;
            neuron_pair_cnt <= 0;
            input_cnt <= 0;
            out_valid <= 0;
            done <= 0;
            input_req <= 0;
            data_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    out_valid <= 0;
                    done <= 0;
                    if (start) begin
                        state <= REQ_DATA;
                        neuron_pair_cnt <= 0;
                        input_cnt <= 0;
                        acc0 <= 0; acc1 <= 0;
                    end
                end

                REQ_DATA: begin
                    out_valid <= 0; 
                    input_req <= 1;
                    state <= WAIT_DATA;
                end

                WAIT_DATA: begin
                    input_req <= 0; 
                    state <= CHECK_ZERO;
                end

                CHECK_ZERO: begin
                    if (data_in == 0) begin
                        if (input_cnt == NUM_INPUTS - 1) begin
                            input_cnt <= 0;
                            state <= BIAS;
                        end else begin
                            input_cnt <= input_cnt + 1;
                            state <= REQ_DATA; 
                        end
                    end else begin
                        state <= STAGE_MULT;
                    end
                end

                STAGE_MULT: begin
                    prod0_reg <= data_in * mem_weights[w_addr_0];
                    prod1_reg <= data_in * mem_weights[w_addr_1];
                    state <= STAGE_ACC;
                end

                STAGE_ACC: begin
                    acc0 <= acc0 + prod0_reg;
                    acc1 <= acc1 + prod1_reg;

                    if (input_cnt == NUM_INPUTS - 1) begin
                        input_cnt <= 0;
                        state <= BIAS;
                    end else begin
                        input_cnt <= input_cnt + 1;
                        state <= REQ_DATA; 
                    end
                end

                BIAS: begin
                    acc0 <= acc0 + mem_biases[neuron_pair_cnt];
                    acc1 <= acc1 + mem_biases[neuron_pair_cnt + 1];
                    state <= OUT_0;
                end

                OUT_0: begin
                    data_out <= activate(acc0);
                    out_valid <= 1;
                    state <= OUT_1;
                end

                OUT_1: begin
                    data_out <= activate(acc1);
                    out_valid <= 1;
                    
                    acc0 <= 0; acc1 <= 0;

                    if (neuron_pair_cnt == NUM_NEURONS - 2) begin
                        state <= DONE;
                    end else begin
                        neuron_pair_cnt <= neuron_pair_cnt + 2;
                        state <= REQ_DATA; 
                    end
                end

                DONE: begin
                    out_valid <= 0;
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule