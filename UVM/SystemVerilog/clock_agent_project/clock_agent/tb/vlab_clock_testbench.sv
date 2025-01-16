/// Header for SMERRITT
/// Clock Testbench

`timescale 1fs/1fs

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "vlab_clock_pkg.sv"
import vlab_clock_pkg::*;

`include "vlab_clock_tb_pkg.sv"
import vlab_clock_tb_pkg::*;

module top;

    bit ref_clk;

    vlab_clock_interface ref_clk_if(ref_clk);
    vlab_clock_interface clk_if_dut (ref_clk_if.clock_pass_thru);
    vlab_clock_interface clk_if_1MHz (ref_clk_if.clock_pass_thru);
    vlab_clock_interface clk_if_100MHz (ref_clk_if.clock_pass_thru);

    /// Set timeformat for uvm_info display data
    initial begin
        $timeformat(-15, 0, " fs", 15);
    end

    /// Simple reference clock for pass_thru, clock_divider, and clock_phase_shift
    /// ref_clk period: 0.25ns / ref_clk freq: 4000 MHz / Duty cycle: 20 high
    initial begin
        ref_clk = 0;
        forever begin
            #200ps;
            ref_clk = ~ref_clk;
            #50ps;
            ref_clk = ~ref_clk;
        end
    end

    /// Start test
    initial begin
        uvm_config_db #(virtual vlab_clock_interface)::set(null, "*", "ref_vif", ref_clk_if );
        uvm_config_db #(virtual vlab_clock_interface)::set(null, "*clk_agt_dut*", "vif", clk_if_dut );
        uvm_config_db #(virtual vlab_clock_interface)::set(null, "*clk_agt_1MHz*", "vif", clk_if_1MHz );
        uvm_config_db #(virtual vlab_clock_interface)::set(null, "*clk_agt_100MHz*", "vif", clk_if_100MHz );
        run_test("vlab_clock_base_test");
    end

    /// Timeout
    initial begin
        #100us;
        $display("Timeout reached");
        $finish();
    end
endmodule : top
