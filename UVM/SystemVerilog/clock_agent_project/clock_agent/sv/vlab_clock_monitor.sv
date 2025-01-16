/// Clock Monitor

class vlab_clock_monitor extends uvm_monitor;
    `uvm_component_utils(vlab_clock_monitor)

    virtual vlab_clock_interface vif;

    uvm_analysis_port #(vlab_clock_sequence_item) mon_ap;

    function new(string name = "vlab_clock_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon_ap = new ("mon_ap", this);

        if(!(uvm_config_db #(virtual vlab_clock_interface)::get(this, "", "vif", vif))) begin
            `uvm_error("NOVIF", "vif not set")
        end
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        vlab_clock_sequence_item mon_item; 

        super.run_phase(phase);
        
        fork
            /// Capture every clock_en edge, log as CLK_ENA
            forever begin
                @(vif.clock_en); 
                write_mon_item(mon_item, CLK_ENA);
            end

            /// Capture every positive clock_out edge, log as CLK_START
            forever begin
                @(posedge vif.clock_out); 
                write_mon_item(mon_item, CLK_START);
            end

            /// Capture every positive clock_in edge, log as CLK_INPUT
            forever begin
                @(posedge vif.clock_in); 
                write_mon_item(mon_item, CLK_INPUT);
            end
        join
    endtask : run_phase

    task write_mon_item(vlab_clock_sequence_item mon_item, vlab_clock_opcode_enum opcode);
        mon_item = vlab_clock_sequence_item::type_id::create("mon_item", this);
        mon_item.opcode = opcode;
        mon_item.clock_en = vif.clock_en;
        mon_item.timestamp = $realtime;
        mon_ap.write(mon_item);
    endtask : write_mon_item

endclass : vlab_clock_monitor

