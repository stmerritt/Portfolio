/// Clock Sequence Item

class vlab_clock_sequence_item extends uvm_sequence_item;
    vlab_clock_opcode_enum opcode;
    time timestamp;

    rand longint unsigned   clock_nominal_freq_Hz;
    rand int unsigned       clock_start_delay_fs;
    rand int unsigned       phase_shift_percent;
    rand int unsigned       clock_divider_val;

    rand bit reset_val;
    rand int ppm_offset;
    rand bit clock_en;

    constraint clock_freq_nonzero_c     { clock_nominal_freq_Hz != 0; }
    constraint max_clock_start_delay_c  { clock_start_delay_fs  < 1_000_000_000; } /// Max clock delay constrained to 1_000 ns
    constraint phase_shift_valid_c      { phase_shift_percent   < 100; }
    constraint clock_div_nonzero_c      { clock_divider_val     != 0; }

    constraint ppm_offset_c         { ppm_offset > -1_000_000;
                                      ppm_offset <  1_000_000; }

    `uvm_object_utils_begin(vlab_clock_sequence_item)
        `uvm_field_enum(    vlab_clock_opcode_enum, opcode, UVM_DEFAULT)
        `uvm_field_int(     clock_nominal_freq_Hz,          UVM_DEC)
        `uvm_field_int(     ppm_offset,                     UVM_DEC)
        `uvm_field_int(     clock_start_delay_fs,           UVM_DEC)
        `uvm_field_int(     phase_shift_percent,            UVM_DEC)
        `uvm_field_int(     clock_divider_val,              UVM_DEC)
        `uvm_field_int(     reset_val,                      UVM_DEFAULT)
        `uvm_field_int(     clock_en,                       UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "vlab_clock_sequence_item");
        super.new(name);
    endfunction : new

    function real calc_actual_frequency_Hz();
        real actual_freq = real'(clock_nominal_freq_Hz) * (1.0 + (real'(ppm_offset) / 1_000_000.0));
        `uvm_info("CLOCK_SEQ_ITEM", $sformatf("Get actual frequency called: nominal: %d Hz, ppm: %d, actual: %.02f Hz", this.clock_nominal_freq_Hz, this.ppm_offset, actual_freq), UVM_HIGH)
        return actual_freq;
    endfunction : calc_actual_frequency_Hz

endclass : vlab_clock_sequence_item
