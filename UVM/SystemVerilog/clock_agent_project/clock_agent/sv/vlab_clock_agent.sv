/// Clock Agent

class vlab_clock_agent extends uvm_agent;

    `uvm_component_utils(vlab_clock_agent)

    vlab_clock_monitor    clk_mon;
    vlab_clock_driver     clk_drv;
    vlab_clock_sequencer_t  clk_sqr;

    function new(string name = "vlab_clock_agent", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        clk_mon  = vlab_clock_monitor::type_id::create("clk_mon", this);

        if(get_is_active()==UVM_ACTIVE) begin
            clk_drv = vlab_clock_driver::type_id::create("clk_drv", this);
            clk_sqr = vlab_clock_sequencer_t::type_id::create("clk_sqr", this);
        end
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if(get_is_active()==UVM_ACTIVE) begin
            clk_drv.seq_item_port.connect(clk_sqr.seq_item_export);
            `uvm_info("CLOCK_AGENT","Clock driver and sequencer connected",UVM_HIGH)
        end
    endfunction : connect_phase
  
endclass : vlab_clock_agent
