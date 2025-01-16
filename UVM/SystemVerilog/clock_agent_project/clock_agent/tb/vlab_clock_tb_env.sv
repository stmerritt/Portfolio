/// Header for SMERRITT
/// Clock Testbench Environment

class vlab_clock_tb_env extends uvm_env;

    `uvm_component_utils(vlab_clock_tb_env)
    vlab_clock_agent clk_agt_dut;
    vlab_clock_agent clk_agt_1MHz;
    vlab_clock_agent clk_agt_100MHz;
    //vlab_clock_agent clk_agt_passive;

    function new(string name = "vlab_clock_tb_env", uvm_component parent);
        super.new(name, parent);
        `uvm_info("CLOCK_ENV", "Constructor", UVM_DEBUG)
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("CLOCK_ENV", "Build Phase", UVM_DEBUG)

        clk_agt_dut = vlab_clock_agent::type_id::create("clk_agt_dut",this);
        clk_agt_1MHz = vlab_clock_agent::type_id::create("clk_agt_1MHz",this);
        clk_agt_100MHz = vlab_clock_agent::type_id::create("clk_agt_100MHz",this);
        //clk_agt_passive = vlab_clock_agent::type_id::create("clk_agt_passive",this);

        //uvm_config_db #(int)::set(this, "clk_agt_passive", "is_active", UVM_PASSIVE);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("CLOCK_ENV", "Connect Phase", UVM_DEBUG)
    endfunction : connect_phase

    task run_phase (uvm_phase phase);
        super.run_phase(phase);

    endtask : run_phase

endclass : vlab_clock_tb_env
