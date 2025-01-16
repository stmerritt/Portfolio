from clock_uvc import *

# Enumerations for active state, trigger edge, and default state
@enum.unique
class reset_active_state_e(Enum):
    RESET_ACTIVE_LOW = 0
    RESET_ACTIVE_HIGH = 1

@enum.unique
class reset_trigger_edge_e(Enum):
    RESET_RISING_EDGE = 0
    RESET_FALLING_EDGE = 1

@enum.unique
class reset_default_state_e(Enum):
    RESET_ASSERTED = 0
    RESET_DEASSERTED = 1

# Reset Configuration Item Class
class clock_cfg_item(uvm_object):
    def __init__(self, name="clock_cfg_item"):
        super().__init__(name)
        self.clock_nominal_freq_Hz    = 100_000_000
        self.clock_start_delay_fs     = 0
        self.phase_shift_percent      = 0
        self.clock_divider_val        = 0
        self.ppm_offset               = 0
        self.reset_val                = 0
        self.prefix                   = ""
        
        self.reset_active_state  = reset_active_state_e.RESET_ACTIVE_HIGH
        self.reset_trigger_edge  = reset_trigger_edge_e.RESET_RISING_EDGE
        self.reset_default_state = reset_default_state_e.RESET_DEASSERTED

    def calc_actual_frequency_Hz(self):
        """
        Calculate the actual clock frequency based on nominal frequency and PPM offset
        """
        actual_freq = float(self.clock_nominal_freq_Hz) * (1.0 + (float(self.ppm_offset) / 1_000_000.0))
        #self.logger.info("Get actual frequency called: nominal:" + f"{self.clock_nominal_freq_Hz.value}", "ppm: " + f"{self.ppm_offset}", "actual: " + f"{actual_freq:.02f}")
        return actual_freq
      
    #def __str__(self):
    #   return f'clock_cfg_item: \n\treset_active_state    {self.reset_active_state} \n\treset_default_state    {self.reset_default_state}'
    def __str__(self):
        return f'clock_cfg_item: \n\tclock_nominal_freq_Hz    {self.clock_nominal_freq_Hz} \n\tclock_start_delay_fs    {self.clock_start_delay_fs}'
  
    @vsc.constraint
    def clock_freq_nonzero_c(self):
        self.clock_nominal_freq_Hz != 0

    def max_clock_start_delay_c(self):
        self.clock_start_delay_fs  < 1_000_000_000  # Max clock delay constrained to 1_000 ns

    def phase_shift_valid_c(self):
        self.phase_shift_percent   < 100

    def clock_div_nonzero_c(self):
        self.clock_divider_val     !=0

    def ppm_offset_c(self):
        self.ppm_offset            > -1_000_000
        self.ppm_offset            <  1_000_000

   
