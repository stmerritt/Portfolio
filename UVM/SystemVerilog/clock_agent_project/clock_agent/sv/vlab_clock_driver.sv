/// Clock Driver

class vlab_clock_driver extends uvm_driver #(vlab_clock_sequence_item);
    virtual vlab_clock_interface vif;
    vlab_clock_sequence_item req, req_prev;

    bit clock_en  = 0;
    bit clock_out = 0;

    int clock_divider_val;
    int phase_shift_percent;
    int clock_in_count = 0;
    int full_period_fs = 0;
    int half_period_fs = 0;
    bit reset_val = 0;    /// The clock_out value expected when clock is disabled
    enum {STANDARD, DIV, SHIFT} clock_mode = STANDARD;
    real t_prev_posedge, t_curr_posedge, t_curr_negedge;
    int clock_input_full_period_fs, clock_input_duty_cycle_high_fs;
    bit clock_in_posedge_flag;

    `uvm_component_utils(vlab_clock_driver)

    function new(string name = "vlab_clock_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!(uvm_config_db #(virtual vlab_clock_interface)::get(this,"","vif",vif))) begin
            `uvm_error("NOVIF","vif not set")
        end
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        clock_en = 0;
        clock_out = 0;
        fork
            get_clock_items();
            run_clock();
            drive_outputs();
            read_clock_input_period();
        join
    endtask : run_phase

    /// This task gets the next item from the queue and drives output signals depending on the opcode
    task get_clock_items();
        forever begin
            `uvm_info("CLOCK_DRIVER", "Getting next item", UVM_HIGH)
            seq_item_port.get_next_item(req);
            if (req_prev != null) end_tr(req_prev);

            accept_tr(req, $time);
            void'(begin_tr(req, "vlab_clock_monitor"));

            `uvm_info("CLOCK_DRIVER", $sformatf("Sending Packet :\n%s", req.sprint()), UVM_LOW)
            case(req.opcode)
                CLK_INIT  : initialize_clock(req);
                CLK_START : start_clock(req);
                CLK_DIV   : start_clock_div(req);
                CLK_SHIFT : start_clock_phase_shift(req);
                CLK_ENA   : enable_clock(req.clock_en);
                default   : `uvm_error("CLOCK_DRIVER", "Attempted to drive packet with invalid opcode")
            endcase

            req_prev = req;

            `uvm_info("CLOCK_DRIVER", "Finishing item", UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask : get_clock_items

    /// This task drives the clock outputs, separate from getting next items so that output clock can be toggling while handling the next clock item
    task run_clock();
        forever begin
            if (clock_en == 1) begin
                case(clock_mode)
                    /// In STANDARD mode, generate clock signal from scratch using given inputs to determine the full period.
                    /// Wait half of the period, then toggle signal. For odd full period, the second toggle waits for (full - half)
                    STANDARD    : begin
                            if ((full_period_fs > 1) && (half_period_fs > 0)) begin
                                clock_out = ~clock_out;
                                #(half_period_fs * 1fs);
                                clock_out = ~clock_out;
                                #((full_period_fs - half_period_fs) * 1fs);
                            end else begin
                                clock_out = reset_val;
                                #1fs;
                            end
                        end

                    /// In DIV mode, the output clock frequency should be equal to the input frequency divided by a clock_divider_val. Duty cycle of input frequency is not preserved.
                    DIV         : begin
                            @(vif.clock_in);
                            if (clock_in_count < (clock_divider_val-1)) begin
                                clock_in_count += 1;
                            end else begin
                                clock_in_count = 0;
                                clock_out = ~clock_out;
                            end
                        end

                    /// In SHIFT mode, the driver waits for positive edges of the input clock and then waits for the phase shift percentage of the input clock period before
                    /// setting the output high. This triggers the second branch to wait for the amount of time the input clock stays high before setting the output low.
                    /// Duty cycle of input signal is preserved. phase_shift_percentage is constrained to be an integer within 0 to 99 inclusively. As this is within a larger
                    /// forever loop, the driver will continue to output a shifted clock until the clock mode changes.
                    SHIFT       : begin
                            fork
                                begin
                                    @(posedge vif.clock_in);
                                    #((real'(clock_input_full_period_fs) * (real'(phase_shift_percent) / 100.0)) * 1fs) clock_out = 1;
                                    clock_in_posedge_flag = 1;
                                end
                                begin
                                    @(posedge clock_in_posedge_flag);
                                    #(clock_input_duty_cycle_high_fs * 1fs) clock_out = 0;
                                    clock_in_posedge_flag = 0;
                                end
                            join_any
                        end

                    default     : begin
                            `uvm_error("CLOCK_DRIVER","Invalid clock mode")
                            clock_out = reset_val;
                            #1fs;
                        end
                endcase
            end else begin
                clock_out = reset_val;
                @(posedge clock_en);
            end
        end
    endtask : run_clock

    task drive_outputs();
        forever begin
            @(clock_en or clock_out);
            vif.clock_en  = clock_en;
            vif.clock_out = clock_out * clock_en;
        end
    endtask : drive_outputs

    function initialize_clock(vlab_clock_sequence_item req);
        `uvm_info("CLOCK_DRIVER", "Initializing Clock", UVM_HIGH)
        reset_val = req.reset_val;
        enable_clock(0);
        clock_out = reset_val;
    endfunction : initialize_clock

    function enable_clock(bit clk_ena);
        `uvm_info("CLOCK_DRIVER", $sformatf("Setting Clock_Enable: %d", clk_ena), UVM_HIGH)
        clock_en = clk_ena;
    endfunction : enable_clock

    task start_clock(vlab_clock_sequence_item req);
        `uvm_info("CLOCK_DRIVER", "Starting Clock in STANDARD mode", UVM_HIGH)
        full_period_fs = 0;
        half_period_fs = 0;
        clock_mode = STANDARD;

        if (req.clock_start_delay_fs == 0) begin
            full_period_fs = $rtoi(1_000_000_000.0 * (1_000_000.0 / req.calc_actual_frequency_Hz()));
            half_period_fs = full_period_fs / 2;
            enable_clock(req.clock_en);
        end
        else begin
            enable_clock(req.clock_en);
            #(req.clock_start_delay_fs * 1fs);
            full_period_fs = $rtoi(1_000_000_000.0 * (1_000_000.0 / req.calc_actual_frequency_Hz()));
            half_period_fs = full_period_fs / 2;
        end
    endtask : start_clock

    function start_clock_div(vlab_clock_sequence_item req);
        `uvm_info("CLOCK_DRIVER", "Starting Clock in CLOCK_DIVIDER mode", UVM_HIGH)
        enable_clock(0);
        clock_mode = DIV;
        clock_in_count = 0;
        clock_divider_val = req.clock_divider_val;
        enable_clock(req.clock_en);
    endfunction : start_clock_div

    task start_clock_phase_shift(vlab_clock_sequence_item req);
        `uvm_info("CLOCK_DRIVER", "Starting Clock in PHASE_SHIFT mode", UVM_HIGH)
        enable_clock(0);
        clock_mode = SHIFT;
        phase_shift_percent = req.phase_shift_percent;
        /// Wait a couple of input clock cycles to ensure accurate input period and duty cycle measurement
        repeat (2) begin
            @(posedge vif.clock_in);
        end
        enable_clock(req.clock_en);
    endtask : start_clock_phase_shift

    task read_clock_input_period();
        forever begin
            @(posedge vif.clock_in)
            t_prev_posedge = t_curr_posedge;
            t_curr_posedge = $realtime;
            clock_input_full_period_fs = (t_curr_posedge - t_prev_posedge); /// Read full clock input period

            @(negedge vif.clock_in)
            t_curr_negedge = $realtime;
            clock_input_duty_cycle_high_fs = (t_curr_negedge - t_curr_posedge); /// Read time that clock input is held high per clock cycle
        end
    endtask : read_clock_input_period
endclass : vlab_clock_driver
