`timescale 1ns / 1ps

module tb_programmable_pic;

    reg        clk;
    reg        rst;
    reg        cs;
    reg        wr;
    reg        rd;
    reg        a0;
    reg  [7:0] tb_data_out;
    reg        tb_drive_bus;
    wire [7:0] data_bus;
    wire       int_req;
    reg        inta;
    reg  [7:0] irq;

    assign data_bus = tb_drive_bus ? tb_data_out : 8'bz;

    programmable_pic dut (
        .clk(clk),
        .rst(rst),
        .cs(cs),
        .wr(wr),
        .rd(rd),
        .a0(a0),
        .data_bus(data_bus),
        .int_req(int_req),
        .inta(inta),
        .irq(irq)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task cpu_write;
        input reg target_a0;
        input reg [7:0] wdata;
        begin
            @(negedge clk);
            cs = 1; wr = 1; rd = 0; a0 = target_a0;
            tb_drive_bus = 1; tb_data_out = wdata;
            @(negedge clk);
            cs = 0; wr = 0; tb_drive_bus = 0;
        end
    endtask

    task cpu_ack;
        begin
            @(negedge clk);
            inta = 1;
            @(negedge clk);
            $display("CPU Received Vector: 0x%h", data_bus);
            inta = 0;
        end
    endtask

    initial begin
        // ***** DUMP WAVEFORM *****
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_programmable_pic);

        // Testbench initialization and stimulus
        rst = 1; cs = 0; wr = 0; rd = 0; a0 = 0;
        tb_drive_bus = 0; tb_data_out = 8'd0;
        inta = 0; irq = 8'd0;

        #25 rst = 0;

        cpu_write(0, 8'h40);
        cpu_write(1, 8'h00);

        #30;

        repeat (10) begin
            #({$random} % 50 + 20);
            irq = $random;

            if (int_req) cpu_ack();

            #10;
            irq = 8'b00000000;

            if ({$random} % 2 == 0) begin
                cpu_write(0, 8'h20);
            end
        end

        #100 $finish;
    end

    initial begin
        $monitor("Time: %4t | IRQ: %b | INT_REQ: %b | INTA: %b | IRR: %b | ISR: %b | IMR: %b",
                 $time, irq, int_req, inta, dut.irr, dut.isr, dut.imr);
    end

endmodule