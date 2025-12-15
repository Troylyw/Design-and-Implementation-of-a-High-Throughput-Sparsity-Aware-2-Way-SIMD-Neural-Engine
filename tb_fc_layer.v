`timescale 1ns/1ps

module tb_fc_layer;

    initial begin
        $dumpfile("wave.vcd");        
        $dumpvars(0, tb_fc_layer);    
    end

    parameter NUM_NEURONS = 10;
    parameter NUM_INPUTS  = 4;
    parameter NUM_TEST_CASES = 5;

    reg clk, rst_n, start;
    reg signed [7:0] data_in;
    wire signed [7:0] data_out;
    wire out_valid, done, input_req;

    reg signed [7:0] test_inputs  [0:(NUM_INPUTS * NUM_TEST_CASES)-1];
    reg signed [7:0] golden_outs  [0:(NUM_NEURONS * NUM_TEST_CASES)-1];

    fc_layer #(
        .NUM_NEURONS(NUM_NEURONS),
        .NUM_INPUTS(NUM_INPUTS)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .data_in(data_in), .data_out(data_out),
        .out_valid(out_valid), .done(done), .input_req(input_req)
    );

    initial begin
        $readmemh("inputs.hex", test_inputs);
        $readmemh("golden_outputs.hex", golden_outs);
    end

    always #5 clk = ~clk;

    integer case_idx;     
    integer input_idx;   
    integer out_chk_idx;  
    integer errors;

    initial begin
        clk = 0; rst_n = 0; start = 0; 
        data_in = 0;
        case_idx = 0; input_idx = 0; out_chk_idx = 0; errors = 0;

        #20 rst_n = 1;
        
        $display("-----------------------------------------");
        $display("Starting Simulation for %0d Test Cases", NUM_TEST_CASES);
        $display("-----------------------------------------");

        for (case_idx = 0; case_idx < NUM_TEST_CASES; case_idx = case_idx + 1) begin
            
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            wait(done);
            
            #20;
        end

        $display("-----------------------------------------");
        if (errors == 0)
            $display("TEST PASSED! All outputs match Golden Model.");
        else
            $display("TEST FAILED! Found %0d errors.", errors);
        $display("-----------------------------------------");
        $finish;
    end

    integer inputs_sent_in_case;
    
    always @(posedge clk) begin
        if (start) begin
            inputs_sent_in_case = 0;
        end
        
        if (input_req) begin
            data_in <= test_inputs[(case_idx * NUM_INPUTS) + (inputs_sent_in_case % NUM_INPUTS)];
            inputs_sent_in_case <= inputs_sent_in_case + 1;
        end
    end

    always @(posedge clk) begin
        if (out_valid) begin
            if (data_out !== golden_outs[out_chk_idx]) begin
                $display("ERROR at Time %t: Case %0d, Neuron Output %0d. Expected %h, Got %h", 
                         $time, case_idx, out_chk_idx % NUM_NEURONS, golden_outs[out_chk_idx], data_out);
                errors = errors + 1;
            end else begin

            end
            out_chk_idx = out_chk_idx + 1;
        end
    end

endmodule