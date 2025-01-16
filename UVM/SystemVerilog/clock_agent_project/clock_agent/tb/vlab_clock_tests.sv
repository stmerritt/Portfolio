/// Header for SMERRITT
/// Clock Test

class vlab_clock_base_test extends uvm_test;

    `uvm_component_utils(vlab_clock_base_test)
    vlab_clock_tb_env clk_tb_env;
    string test_name = "vlab_clock_demo_test";
    
    uvm_analysis_imp #(vlab_clock_sequence_item, vlab_clock_base_test) analysis_imp;

    /// Expected outputs
    longint unsigned    expected_nominal_freq_Hz      = 1_000_000_000;
    int             expected_ppm_extreme          = 600_000;
    int             expected_delay_fs             = 200_000;
    int             expected_clock_div_val        = 5;
    int             expected_phase_shift_percent  = 75;

    time t_enable, t_first, t_eleventh;
    time t_in_0, t_in_1, t_phase_shift;
    int clock_count;
    longint unsigned expected_actual_freq_Hz;
    int expected_ppm_offset;

    /// Actual results
    longint unsigned    actual_freq_Hz, actual_period_fs;
    longint unsigned    actual_input_freq_Hz, actual_input_period_fs;
    int             actual_ppm_offset;
    int             actual_delay_fs;
    int             actual_clock_div_val;
    int             actual_phase_shift_percent;

    function new(string name = "vlab_clock_base_test", uvm_component parent);
        super.new(name, parent);
        analysis_imp = new ("analysis_imp", this);
        `uvm_info("CLOCK_TEST", "Constructor", UVM_DEBUG)
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("CLOCK_TEST", "Build Phase", UVM_DEBUG)

        clk_tb_env = vlab_clock_tb_env::type_id::create("clk_tb_env", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("CLOCK_TEST", "Connect Phase", UVM_DEBUG)

        clk_tb_env.clk_agt_dut.clk_mon.mon_ap.connect(analysis_imp);
    endfunction : connect_phase

    virtual function void write(vlab_clock_sequence_item item);
        case (item.opcode)
            CLK_ENA   : write_ena(item);
            CLK_START : write_start(item);
            CLK_INPUT : write_input(item);
            default   : `uvm_info("CLOCK_TEST", $sformatf("Write called: %d, %d, %d", item.opcode, item.clock_en, item.timestamp), UVM_HIGH)
        endcase
    endfunction : write

    /// Called every time clock enable changes. If high, save timestamp for calculating clock delay. If low, reset clock_count
    function void write_ena(vlab_clock_sequence_item item);
        `uvm_info("CLOCK_TEST", $sformatf("Clock enable change to %d detected at %d", item.clock_en, item.timestamp), UVM_HIGH);
        if (item.clock_en == 1) begin
            t_enable = item.timestamp;
        end
        else begin
            clock_count = 0;
        end
    endfunction : write_ena

    /// Called every positive clock_out edge. If first occurrence since clock enable went high, save timestamp for calculating clock delay and output frequency
    /// Also save difference between first clock output and most recent clock input for phase shift testing
    /// 11th clock cycle used for determining frequency because it should provide ample time for issues to occur within the first 10 full output clock cycles
    function void write_start(vlab_clock_sequence_item item);
        clock_count++;
        if (clock_count == 1) begin
            t_first = item.timestamp;

            t_phase_shift = t_first - t_in_1;
            /// Possible issue if first clock output pulse coincides with clock input, which would indicate 100% phase shift, equivalent to 0% phase shift
            if (t_phase_shift == (t_in_1 - t_in_0)) begin
                t_phase_shift = 0;
            end

            `uvm_info("CLOCK_TEST", $sformatf("First clock edge detected at: %d", t_first), UVM_HIGH);
        end
        else if (clock_count == 11) begin
            t_eleventh = item.timestamp;
            `uvm_info("CLOCK_TEST", $sformatf("Eleventh clock edge detected at: %d", t_eleventh), UVM_HIGH);
        end

        /// Test for clock pulse occuring when output should be disabled. Current clock cycle is allowed to complete, but there should be no positive edges when clock_en is low
        if (item.clock_en == 0) begin
            `uvm_error("CLOCK_TEST", "Clock pulse detected while output should be disabled")
        end

        `uvm_info("CLOCK_TEST", $sformatf("Current clock count: %d at %d fs", clock_count, item.timestamp), UVM_HIGH);
    endfunction : write_start

    function void write_input(vlab_clock_sequence_item item);
        t_in_0 = t_in_1;
        t_in_1 = item.timestamp;
        if (t_in_1 > t_in_0) begin
            actual_input_period_fs = t_in_1 - t_in_0;
            actual_input_freq_Hz = longint'(1_000_000_000.0 * (1_000_000.0 / (real'(actual_input_period_fs))));
        end
    endfunction : write_input

    function real get_actual_freq_Hz(longint unsigned nominal_freq_Hz, int ppm_offset);
        return (real'(nominal_freq_Hz) * (1.0 + (real'(ppm_offset) / 1_000_000.0)));
    endfunction : get_actual_freq_Hz

    function int calc_ppm_offset(longint unsigned actual_freq_Hz, longint unsigned nominal_freq_Hz);
        return int'((1_000_000.0 * ((real'(actual_freq_Hz) / real'(nominal_freq_Hz)) - 1.0)));
    endfunction : calc_ppm_offset

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        phase.raise_objection(this);
        begin
            vlab_clock_enable_seq disable_seq;
            disable_seq = vlab_clock_enable_seq::type_id::create("disable_seq");
            disable_seq.randomize() with {  clock_en  == 0;
                                            reset_val == 0; };
            #5ns;

            start_constant_clock(.agt(clk_tb_env.clk_agt_1MHz),   .freq_Hz(1000000));
            start_constant_clock(.agt(clk_tb_env.clk_agt_100MHz), .freq_Hz(100000000));

            if (test_name == "vlab_clock_basic_test") begin
                run_basic_test();
            end
            else if (test_name == "vlab_clock_enable_test") begin
                run_enable_test();
            end
            else if (test_name == "vlab_clock_start_delay_test") begin
                run_delay_test();
            end
            else if (test_name == "vlab_clock_ppm_offset_test") begin
                run_ppm_offset_test();
            end
            else if (test_name == "vlab_clock_div_test") begin
                run_div_test();
            end
            else if (test_name == "vlab_clock_phase_shift_test") begin
                run_phase_shift_test();
            end
            else if (test_name == "vlab_clock_demo_test") begin
                /// Run all tests for waveform generation and demo purposes
                run_basic_test();
                disable_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
                #10ns;

                run_enable_test();
                disable_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
                #10ns;

                run_delay_test();
                disable_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
                #10ns;

                run_ppm_offset_test();
                disable_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
                #10ns;

                run_div_test();
                disable_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
                #10ns;

                run_phase_shift_test();              
                disable_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
            end
            else begin
                `uvm_error("CLOCK_TEST", "Invalid test name")
            end

            #5us;
        end
        phase.drop_objection(this);
    endtask : run_phase

    task verify_standard_test(int unsigned test_delay_fs, int test_ppm_offset);
        /// Verify clock delay
        actual_delay_fs = t_first - t_enable;
        if (actual_delay_fs != test_delay_fs) begin
            `uvm_error("CLOCK_TEST", $sformatf("FAIL: Actual clock delay (%12d fs) does not match expected clock delay (%12d fs)", actual_delay_fs, test_delay_fs))
        end
        else begin
            `uvm_info("CLOCK_TEST", $sformatf("PASS: Actual clock delay (%12d fs) matches expected clock delay (%12d fs)", actual_delay_fs, test_delay_fs), UVM_HIGH)
        end

        /// Verify clock frequency
        if (clock_count < 11) begin
            `uvm_error("CLOCK_TEST", "Insufficient clock cycles for measuring clock frequency")
        end
        else begin
            actual_period_fs = (t_eleventh - t_first) / 10;
            if (actual_period_fs == 0) begin
                `uvm_error("CLOCK_TEST", "Unable to calculate clock period")
            end
            else begin
                actual_freq_Hz = longint'(1_000_000_000.0 * (1_000_000.0 / real'(actual_period_fs)));
                expected_actual_freq_Hz = get_actual_freq_Hz(expected_nominal_freq_Hz, test_ppm_offset);
                if (actual_freq_Hz != expected_actual_freq_Hz) begin
                    `uvm_error("CLOCK_TEST", $sformatf("FAIL: Actual clock freq  (%12d Hz) does not match expected clock freq  (%12d Hz)", actual_freq_Hz, expected_actual_freq_Hz))
                end
                else begin
                    `uvm_info("CLOCK_TEST", $sformatf("PASS: Actual clock freq  (%12d Hz) matches expected clock freq  (%12d Hz)", actual_freq_Hz, expected_actual_freq_Hz), UVM_HIGH)
                end
            end
        end

        /// Verify ppm offset
        if (actual_freq_Hz != 0) begin
            actual_ppm_offset = calc_ppm_offset(actual_freq_Hz, expected_nominal_freq_Hz);
            if (actual_ppm_offset != test_ppm_offset) begin
                `uvm_error("CLOCK_TEST", $sformatf("FAIL: Actual ppm_offset  (%12d   ) does not match expected ppm_offset  (%12d   )", actual_ppm_offset, test_ppm_offset))
            end
            else begin
                `uvm_info("CLOCK_TEST", $sformatf("PASS: Actual ppm_offset  (%12d   ) matches expected ppm_offset  (%12d   )", actual_ppm_offset, test_ppm_offset), UVM_HIGH)
            end
        end
        else begin
            `uvm_error("CLOCK_TEST", "Unable to calculate clock frequency")
        end
            
    endtask : verify_standard_test

    task verify_div_test();
        /// Verify output frequency is correct multiple of input frequency
        if (clock_count < 11) begin
            `uvm_error("CLOCK_TEST", "Insufficient clock cycles for measuring clock frequency")
        end
        else begin
            actual_period_fs = (t_eleventh - t_first) / 10;
            if (actual_period_fs == 0) begin
                `uvm_error("CLOCK_TEST", "Unable to calculate clock period")
            end
            else begin
                actual_freq_Hz = longint'(1_000_000_000.0 * (1_000_000.0 / real'(actual_period_fs)));
                actual_clock_div_val = int'(real'(actual_input_freq_Hz) / real'(actual_freq_Hz));
                if (actual_clock_div_val != expected_clock_div_val) begin
                    `uvm_error("CLOCK_TEST", $sformatf("FAIL: Actual clock divider (%12d   ) does not match expected clock divider (%12d   )", actual_clock_div_val, expected_clock_div_val))
                end
                else begin
                    `uvm_info("CLOCK_TEST", $sformatf("PASS: Actual clock divider (%12d   ) matches expected clock divider (%12d   )", actual_clock_div_val, expected_clock_div_val), UVM_HIGH)
                end
            end
        end
        
    endtask : verify_div_test

    task verify_phase_shift_test();
        /// Verify same input frequency and output frequency
        if (clock_count < 11) begin
            `uvm_error("CLOCK_TEST", "Insufficient clock cycles for measuring clock frequency")
        end
        else begin
            actual_period_fs = (t_eleventh - t_first) / 10;
            if (actual_period_fs == 0) begin
                `uvm_error("CLOCK_TEST", "Unable to calculate clock period")
            end
            else begin
                actual_freq_Hz = longint'(1_000_000_000.0 * (1_000_000.0 / real'(actual_period_fs)));
                if (actual_freq_Hz != actual_input_freq_Hz) begin
                    `uvm_error("CLOCK_TEST", $sformatf("FAIL: Actual clock freq  (%12d Hz) does not match input clock freq  (%12d Hz)", actual_freq_Hz, actual_input_freq_Hz))
                end
                else begin
                    `uvm_info("CLOCK_TEST", $sformatf("PASS: Actual clock freq  (%12d Hz) matches input clock freq  (%12d Hz)", actual_freq_Hz, actual_input_freq_Hz), UVM_HIGH)
                end
            end
        end

        /// Verify phase_shift value
        if (actual_input_period_fs != 0) begin
            actual_phase_shift_percent = int'(100.0 * (real'(t_phase_shift) / real'(actual_input_period_fs)));
            if (actual_phase_shift_percent != expected_phase_shift_percent) begin
                `uvm_error("CLOCK_TEST", $sformatf("FAIL: Actual phase shift (%12d %% ) does not match input phase shift (%12d %% )", actual_phase_shift_percent, expected_phase_shift_percent))
            end
            else begin
                `uvm_info("CLOCK_TEST", $sformatf("PASS: Actual phase shift (%12d %% ) matches input phase shift (%12d %% )", actual_phase_shift_percent, expected_phase_shift_percent), UVM_HIGH)
            end
        end
        else begin
            `uvm_error("CLOCK_TEST", $sformatf("Unable to determine input clock period"))
        end
    endtask : verify_phase_shift_test

    task start_constant_clock(vlab_clock_agent agt, longint unsigned freq_Hz);
        vlab_clock_basic_seq constant_seq;
        constant_seq = vlab_clock_basic_seq::type_id::create("constant_seq");
        constant_seq.randomize() with { clock_freq_Hz == freq_Hz;
                                        reset_val == 0;
                                        clock_start_delay_fs == 0;
                                        ppm_offset == 0;
                                    };
        constant_seq.start(agt.clk_sqr);
    endtask : start_constant_clock

    task run_basic_test();
        fork
            begin
                /// Thread 1: main basic test
                vlab_clock_basic_seq basic_seq;
                basic_seq = vlab_clock_basic_seq::type_id::create("basic_seq");
                basic_seq.randomize() with {    clock_freq_Hz == expected_nominal_freq_Hz;
                                                reset_val == 0;
                                                clock_start_delay_fs == 0;
                                                ppm_offset == 0;
                                            };
                basic_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
            end
            begin
                /// Thread 2: Let test run for 50ns, then verify results
                #50ns;
                verify_standard_test(.test_delay_fs(0), .test_ppm_offset(0));
            end
        join
    endtask : run_basic_test

    task run_enable_test();
        fork
            begin
                /// Thread 1: start basic clock
                vlab_clock_basic_seq basic_seq;
                vlab_clock_enable_seq enable_seq;

                basic_seq = vlab_clock_basic_seq::type_id::create("basic_seq");
                basic_seq.randomize() with {    clock_freq_Hz == expected_nominal_freq_Hz;
                                                reset_val == 0;
                                                clock_start_delay_fs == 0;
                                                ppm_offset == 0;
                                            };
                basic_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);

                /// Wait 20ns and verify clock
                #20ns;
                verify_standard_test(.test_delay_fs(0), .test_ppm_offset(0));

                /// Disable clock
                enable_seq = vlab_clock_enable_seq::type_id::create("enable_seq");
                enable_seq.randomize() with {   clock_en  == 0;
                                                reset_val == 0; };
                enable_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);

                /// Wait 10ns and re-enable clock
                #10ns;
                enable_seq.randomize() with {   clock_en  == 1;
                                                reset_val == 0; };
                enable_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
            end
            begin
                /// Thread 2: Let test run for 50ns, then verify results
                #50ns;
                verify_standard_test(.test_delay_fs(0), .test_ppm_offset(0));
            end
        join
    endtask : run_enable_test

    task run_delay_test();
        fork
            begin
                /// Thread 1: main clock delay test
                vlab_clock_start_delay_seq delay_seq;
                delay_seq = vlab_clock_start_delay_seq::type_id::create("delay_seq");
                delay_seq.randomize() with  {   clock_freq_Hz == expected_nominal_freq_Hz;
                                                clock_start_delay_fs == expected_delay_fs;
                                                reset_val == 0;
                                            };
                delay_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
            end
            begin
                /// Thread 2: Let test run for 50ns, then verify results
                #50ns;
                verify_standard_test(.test_delay_fs(expected_delay_fs), .test_ppm_offset(0));
            end
        join
    endtask : run_delay_test

    task run_ppm_offset_test();
        fork
            begin
                /// Thread 1: main ppm offset test
                vlab_clock_ppm_offset_seq ppm_seq;
                ppm_seq = vlab_clock_ppm_offset_seq::type_id::create("ppm_seq");
                ppm_seq.randomize() with    {   clock_freq_Hz == expected_nominal_freq_Hz;
                                                ppm_offset inside {-expected_ppm_extreme, 0, expected_ppm_extreme};
                                                reset_val == 0;
                                            };
                expected_ppm_offset = ppm_seq.ppm_offset;
                ppm_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
            end
            begin
                /// Thread 2: Let test run for 50ns, then verify results
                #50ns;
                verify_standard_test(.test_delay_fs(0), .test_ppm_offset(expected_ppm_offset));
            end
        join
    endtask : run_ppm_offset_test

    task run_div_test();
        fork
            begin
                /// Thread 1: main clock divider test
                vlab_clock_div_seq div_seq;
                div_seq = vlab_clock_div_seq::type_id::create("div_seq");
                div_seq.randomize() with { clock_divider_val == expected_clock_div_val; };
                div_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
            end
            begin
                /// Thread 2: Let test run for 50ns, then verify results
                #50ns;
                verify_div_test();
            end
        join
    endtask : run_div_test

    task run_phase_shift_test();
        fork
            begin
                /// Thread 1: main clock divider test
                vlab_clock_phase_shift_seq shift_seq;
                shift_seq = vlab_clock_phase_shift_seq::type_id::create("shift_seq");
                shift_seq.randomize() with { phase_shift_percent == expected_phase_shift_percent; };
                shift_seq.start(clk_tb_env.clk_agt_dut.clk_sqr);
            end
            begin
                /// Thread 2: Let test run for 50ns, then verify results
                #50ns;
                verify_phase_shift_test();
            end
        join
    endtask : run_phase_shift_test

endclass : vlab_clock_base_test

