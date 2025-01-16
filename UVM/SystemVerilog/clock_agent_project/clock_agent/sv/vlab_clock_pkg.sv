/// Clock Package

`ifndef VLAB_CLK_PKG_SV 
`define VLAB_CLK_PKG_SV
`timescale 1fs/1fs

package vlab_clock_pkg;
    /// UVM library files
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    /// Project enums
    typedef enum {CLK_INIT, CLK_ENA, CLK_START, CLK_DIV, CLK_SHIFT, CLK_INPUT} vlab_clock_opcode_enum;

    /// Project files
    `include "vlab_clock_sequence_item.sv"
    typedef uvm_sequencer #(vlab_clock_sequence_item) vlab_clock_sequencer_t;
    `include "vlab_clock_seq_lib.sv"
    `include "vlab_clock_driver.sv"
    `include "vlab_clock_monitor.sv"
    `include "vlab_clock_agent.sv"
endpackage

`include "vlab_clock_interface.sv"
`endif // VLAB_CLK_PKG_SV
