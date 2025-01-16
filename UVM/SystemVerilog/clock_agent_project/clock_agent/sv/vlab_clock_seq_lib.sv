/// Clock Sequence Library

class vlab_clock_base_seq extends uvm_sequence #(vlab_clock_sequence_item); 
    `uvm_object_utils(vlab_clock_base_seq)

    vlab_clock_sequence_item req;

    rand longint unsigned   clock_freq_Hz;
    rand int unsigned   clock_start_delay_fs;
    rand int unsigned   clock_divider_val;
    rand int unsigned   phase_shift_percent;

    rand int    ppm_offset;
    rand bit    clock_en;
    rand bit    reset_val;

    constraint clock_freq_min_c             {   clock_freq_Hz > 0; }
    constraint clock_divider_min_c          {   clock_divider_val > 0; }
    constraint phase_shift_percent_max_c    {   phase_shift_percent < 100; }
    constraint ppm_offset_range_c           {   ppm_offset inside {[-999_999:999_999]}; }

    function new(string name = "vlab_clock_base_seq");
        super.new(name);
    endfunction : new

    task body();
        req = vlab_clock_sequence_item::type_id::create("req");
        start_item(req);
        if(!req.randomize()) begin
            `uvm_error("CLOCK_BASE_SEQ", $sformatf("Randomization failed."));
        end
        finish_item(req);
    endtask : body

    task initialize_clock(vlab_clock_sequence_item req, bit reset);
        bit OK;
        start_item(req);
        OK = req.randomize() with { reset_val == reset;
                                    clock_en  == 0; };
        if(!OK) begin
            `uvm_error("CLOCK_INIT_SEQ", $sformatf("Randomization failed."));
        end
        req.opcode = CLK_INIT;
        finish_item(req);        
    endtask : initialize_clock

    task start_clock(longint unsigned clock_freq, bit reset, int unsigned clock_start_delay, int ppm, vlab_clock_sequence_item req);
        bit OK;
        start_item(req);
        OK = req.randomize() with {  clock_nominal_freq_Hz   == clock_freq;
                                     reset_val               == reset; 
                                     clock_start_delay_fs    == clock_start_delay;
                                     ppm_offset              == ppm;
                                     clock_en                == 1;
                                  };
        if(!OK) begin
            `uvm_error("CLOCK_START_SEQ", $sformatf("Randomization failed."));
        end
        req.opcode = CLK_START;
        finish_item(req);
    endtask : start_clock

    task start_clock_div(vlab_clock_sequence_item req, int clock_div_val);
        bit OK;
        start_item(req);
        OK = req.randomize() with {  clock_divider_val  == clock_div_val;
                                     clock_en           == 1;
                                  };
        if(!OK) begin
            `uvm_error("CLOCK_DIV_SEQ", $sformatf("Randomization failed."));
        end
        req.opcode = CLK_DIV;
        finish_item(req);
    endtask : start_clock_div

    task start_clock_phase_shift(vlab_clock_sequence_item req, int phase_shift);
        bit OK;
        start_item(req);
        OK = req.randomize() with { phase_shift_percent == phase_shift;
                                    clock_en            == 1;
                                  };
        if(!OK) begin
            `uvm_error("CLOCK_SHIFT_SEQ", $sformatf("Randomization failed."));
        end
        req.opcode = CLK_SHIFT;
        finish_item(req);
    endtask : start_clock_phase_shift

    task enable_clock(vlab_clock_sequence_item req);
        start_item(req);
        req.clock_en  = clock_en;
        req.reset_val = reset_val;
        req.opcode    = CLK_ENA;
        finish_item(req);        
    endtask : enable_clock
endclass : vlab_clock_base_seq

class vlab_clock_basic_seq extends vlab_clock_base_seq;
    `uvm_object_utils(vlab_clock_basic_seq)

    function new(string name = "vlab_clock_basic_seq");
        super.new(name);
    endfunction : new

    task body();
        req = vlab_clock_sequence_item::type_id::create("req");
        `uvm_info("CLOCK_BASIC_SEQ", "Starting sequence", UVM_HIGH)
        initialize_clock(req, reset_val);
        start_clock(.req(req), .clock_freq(clock_freq_Hz), .reset(reset_val), .clock_start_delay(clock_start_delay_fs), .ppm(ppm_offset));

    endtask : body
endclass : vlab_clock_basic_seq

class vlab_clock_enable_seq extends vlab_clock_base_seq;
    `uvm_object_utils(vlab_clock_enable_seq)

    function new(string name = "vlab_clock_enable_seq");
        super.new(name);
    endfunction : new

    task body();
        req = vlab_clock_sequence_item::type_id::create("req");
        enable_clock(req);
    endtask : body
endclass : vlab_clock_enable_seq

class vlab_clock_start_delay_seq extends vlab_clock_base_seq;
    `uvm_object_utils(vlab_clock_start_delay_seq)

    function new(string name = "vlab_clock_start_delay_seq");
        super.new(name);
    endfunction : new

    task body();
        req = vlab_clock_sequence_item::type_id::create("req");
        `uvm_info("CLOCK_DELAY_SEQ", "Starting sequence", UVM_HIGH)
        initialize_clock(req, reset_val);
        start_clock(.req(req), .clock_freq(clock_freq_Hz), .reset(reset_val), .clock_start_delay(clock_start_delay_fs), .ppm(0));
    endtask : body
endclass : vlab_clock_start_delay_seq

class vlab_clock_ppm_offset_seq extends vlab_clock_base_seq;
    `uvm_object_utils(vlab_clock_ppm_offset_seq)

    function new(string name = "vlab_clock_ppm_offset_seq");
        super.new(name);
    endfunction : new

    task body();
        req = vlab_clock_sequence_item::type_id::create("req");
        `uvm_info("CLOCK_PPM_SEQ", "Starting sequence", UVM_HIGH)
        initialize_clock(req, reset_val);
        start_clock(.req(req), .clock_freq(clock_freq_Hz), .reset(reset_val), .clock_start_delay(0), .ppm(ppm_offset));
    endtask : body
endclass : vlab_clock_ppm_offset_seq

class vlab_clock_div_seq extends vlab_clock_base_seq;
    `uvm_object_utils(vlab_clock_div_seq)

    function new(string name = "vlab_clock_div_seq");
        super.new(name);
    endfunction : new

    task body();
        req = vlab_clock_sequence_item::type_id::create("req");
        `uvm_info("CLOCK_DIV_SEQ", "Starting sequence", UVM_HIGH)
        initialize_clock(req, 0);
        start_clock_div(req, clock_divider_val);
    endtask : body
endclass : vlab_clock_div_seq

class vlab_clock_phase_shift_seq extends vlab_clock_base_seq;
    `uvm_object_utils(vlab_clock_phase_shift_seq)

    function new(string name = "vlab_clock_phase_shift_seq");
        super.new(name);
    endfunction : new

    task body();
        req = vlab_clock_sequence_item::type_id::create("req");
        `uvm_info("CLOCK_SHIFT_SEQ", "Starting sequence", UVM_HIGH)
        initialize_clock(req, 0);
        start_clock_phase_shift(req, phase_shift_percent);
    endtask : body
endclass : vlab_clock_phase_shift_seq
