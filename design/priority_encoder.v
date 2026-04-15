`timescale 1ns / 1ps

module priority_encoder (
    input  wire [7:0] req,
    output reg  [2:0] highest,
    output reg        any_req
);


    always @(*) begin
        any_req = 1'b1;
        if      (req[0]) highest = 3'd0;
        else if (req[1]) highest = 3'd1;
        else if (req[2]) highest = 3'd2;
        else if (req[3]) highest = 3'd3;
        else if (req[4]) highest = 3'd4;
        else if (req[5]) highest = 3'd5;
        else if (req[6]) highest = 3'd6;
        else if (req[7]) highest = 3'd7;
        else begin
            highest = 3'd0;
            any_req = 1'b0;
        end
    end

endmodule