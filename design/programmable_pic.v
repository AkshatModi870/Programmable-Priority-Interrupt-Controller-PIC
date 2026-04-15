`timescale 1ns / 1ps

module programmable_pic (
    input  wire       clk,
    input  wire       rst,
    input  wire       cs,
    input  wire       wr,
    input  wire       rd,
    input  wire       a0,
    inout  wire [7:0] data_bus,
    output reg        int_req,
    input  wire       inta,
    input  wire [7:0] irq
);

    reg [7:0] irr;
    reg [7:0] isr;
    reg [7:0] imr;
    reg [7:0] base_vector;
    reg [7:0] data_out;
    reg       drive_bus;
    reg [7:0] irq_prev;

    wire [7:0] data_in = data_bus;
    assign data_bus = drive_bus ? data_out : 8'bz;

    wire [2:0] highest_irr;
    wire       any_irr;
    wire [7:0] active_req = irr & ~imr;

    priority_encoder pe_irr (
        .req(active_req),
        .highest(highest_irr),
        .any_req(any_irr)
    );

    wire [2:0] highest_isr;
    wire       any_isr;

    priority_encoder pe_isr (
        .req(isr),
        .highest(highest_isr),
        .any_req(any_isr)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            irr         <= 8'd0;
            isr         <= 8'd0;
            imr         <= 8'hFF;
            base_vector <= 8'd0;
            irq_prev    <= 8'd0;
            int_req     <= 1'b0;
            drive_bus   <= 1'b0;
            data_out    <= 8'd0;
        end else begin
            irq_prev <= irq;
            irr <= irr | (irq & ~irq_prev);

            if (cs && wr) begin
                if (a0 == 1'b0) begin
                    if (data_in == 8'h20) begin
                        if (any_isr) isr[highest_isr] <= 1'b0;
                    end else begin
                        base_vector <= data_in;
                    end
                end else begin
                    imr <= data_in;
                end
            end

            if (inta) begin
                drive_bus <= 1'b1;
                if (any_irr) begin
                    data_out <= base_vector + {5'd0, highest_irr};
                    isr[highest_irr] <= 1'b1;
                    irr[highest_irr] <= 1'b0;
                end else begin
                    data_out <= 8'hFF;
                end
            end else if (cs && rd) begin
                drive_bus <= 1'b1;
                if (a0 == 1'b0) data_out <= irr;
                else            data_out <= imr;
            end else begin
                drive_bus <= 1'b0;
            end

            if (any_irr) begin
                if (!any_isr || (highest_irr < highest_isr)) begin
                    int_req <= 1'b1;
                end else begin
                    int_req <= 1'b0;
                end
            end else begin
                int_req <= 1'b0;
            end

            if (inta) int_req <= 1'b0;
        end
    end

endmodule