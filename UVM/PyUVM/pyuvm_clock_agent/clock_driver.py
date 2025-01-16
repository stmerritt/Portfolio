from clock_uvc import *
# test

class clock_driver(uvm_driver):
    """
    Vlab Clock Driver for pyuvm
    """
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.req_prev = None
        self.cfg_item = None  # Configuration item

        self.clock_en = 0

        self.clock_divider_val = 0
        self.phase_shift_percent = 0
        self.clock_in_count = 0
        self.full_period_fs = 0
        self.half_period_fs = 0
        self.reset_val = 0  # The clock_out value expected when clock is disabled
        self.clock_mode = "STANDARD"
        self.t_prev_posedge = 0.0
        self.t_curr_posedge = 0.0
        self.t_curr_negedge = 0.0
        self.clock_input_full_period_fs = 0
        self.clock_input_duty_cycle_high_fs = 0
        self.clock_in_posedge_flag = 0


    def build_phase(self):
        super().build_phase()


    def connect_phase(self):
        super().connect_phase()
        prefix = self.cfg_item.prefix
        self.clock_out =   getattr(cocotb.top, (prefix + "clk"))

        
    def start_of_simulation_phase(self):
        self.logger.debug("Start of simulation phase")
        # Set the reset based on default state
        self.logger.debug("self.cfg_item.reset_default_state: " + f"{self.cfg_item.reset_default_state}")
        if self.cfg_item.reset_default_state.value == reset_default_state_e.RESET_ASSERTED.value:
            self.reset_val = self.cfg_item.reset_active_state
        else:
            self.reset_val = not self.cfg_item.reset_active_state
        self.logger.debug("self.cfg_item.reset_default_state after setting default state: " + f"{self.cfg_item.reset_default_state}")
        self.clock_out.value = 0


    async def run_phase(self):
        """
        Main run_phase for the clock driver. Runs multiple tasks concurrently.
        """
        self.logger.debug("Clock Driver run_phase started")
        self.clock_en = 0
        self.clock_out.value = 0
        get_clock_items = cocotb.start_soon(self.get_clock_items())
        run_clock = cocotb.start_soon(self.run_clock())

            
    # Method to for the config from the Reset Agent
    def set_cfg(self, new_cfg_item):
        self.logger.debug("Setting Config Object")        
        self.cfg_item = new_cfg_item
        # print the config object contents here
        self.logger.debug("Printing Config Object")        
        self.logger.debug(self.cfg_item.convert2string())
        

    async def get_clock_items(self):
        """Task to fetch clock items and handle requests."""
        while True:
            self.logger.debug("Getting next item")
            req   = await self.seq_item_port.get_next_item()
            self.__flag_transaction_completed = 0
            self.__flag_transaction_started = 1

            self.logger.debug(req.convert2string())
            self.logger.debug("req.opcode: " + f"{req.opcode}")
            if req.opcode.value == clock_opcode_e.CLK_START.value:
                self.logger.debug("Running start_clock")
                await self.start_clock(req)
            #elif req.opcode == "CLK_DIV":
            #    await self.start_clock_div(req)
            #elif req.opcode == "CLK_SHIFT":
            #    await self.start_clock_phase_shift(req)
            else:
                self.logger.error("Invalid opcode received")
            self.logger.debug("Finishing item")

            self.seq_item_port.item_done()
            self.__flag_transaction_completed = 1
            self.__flag_transaction_started = 0  

            
    async def run_clock(self):
        """Task to drive the clock outputs."""
        self.logger.debug("Inside run_clock()")
            
        while True:
            if (self.full_period_fs > 1) and (self.half_period_fs > 0) and (self.clock_en == 1):
                self.clock_out.value = 1 - self.clock_out.value
                await Timer(self.half_period_fs, units="fs")
                self.clock_out.value = 1 - self.clock_out.value
                await Timer((self.full_period_fs - self.half_period_fs), units="fs")
            else:
                await Timer(1, units="fs")


    def initialize_clock(self, req):
        """Initialize the clock."""
        self.logger.debug("Initializing Clock")
        self.reset_val = req.reset_val
        self.logger.debug("self.reset_val: " + f"{self.reset_val}")        
        self.clock_out.value = 0


    async def start_clock(self, req):
        """Start the clock in STANDARD mode."""
        self.logger.debug("Starting Clock in STANDARD mode")
        self.full_period_fs = 0
        self.half_period_fs = 0
        self.clock_mode = "STANDARD"
        if self.cfg_item.clock_start_delay_fs == 0:
            self.logger.debug("Calculated Actual Frequency: " + f"{self.cfg_item.calc_actual_frequency_Hz()}" + " Hz")
            self.full_period_fs = int(1e9 * (1e6 / self.cfg_item.calc_actual_frequency_Hz()))
            self.logger.debug("full_period_fs =" + f"{self.full_period_fs}")
            self.half_period_fs = int(self.full_period_fs / 2)
            self.logger.debug("half_period_fs =" + f"{self.half_period_fs}")
            self.clock_en = 1
        else:
            self.clock_en = 1
            await Timer(self.cfg_item.clock_start_delay_fs, units="fs")
            self.full_period_fs = int(1e9 * (1e6 / self.cfg_item.calc_actual_frequency_Hz()))
            self.half_period_fs = int(self.full_period_fs / 2)


    async def read_clock_input_period(self):
        """Measure the input clock's period and duty cycle."""
        while True:
            await cocotb.triggers.RisingEdge(self.clock_in)
            self.t_prev_posedge = self.t_curr_posedge
            self.t_curr_posedge = self.get_sim_time('fs')
            self.clock_input_full_period_fs = self.t_curr_posedge - self.t_prev_posedge
            self.logger.debug("clock_input_full_period_fs =" + f"{self.clock_input_full_period_fs.value}")

            await cocotb.triggers.FallingEdge(self.clock_in)
            self.t_curr_negedge = self.get_sim_time('fs')
            self.clock_input_duty_cycle_high_fs = self.t_curr_negedge - self.t_curr_posedge
            self.logger.debug("clock_input_duty_cycle_high_fs =" + f"{self.clock_input_duty_cycle_high_fs.value}")
