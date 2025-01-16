from clock_uvc import *

@vsc.randobj
class clock_base_seq(uvm_sequence):
    def __init__(self, name="clock_base_seq"):
        super().__init__(name)
        #self.clock_seq_type         = clock_seq_type_e.RESET_ASSERT  # Default value
        #self.synchronization_type   = synchronization_type_e.RESET_ASYNCHRONOUS  # Default value
        self.clock_en     = None
        self.reset_val    = None
        
    async def body(self):
        await super().body()
        clock_item = clock_seq_item() 
        
    #async def start_clock_div(self, clock_div_val):
    #    req = clock_seq_item("req")
    #    req.randomize()
    #    with req.randomize_with() as it:
    #      it.clock_divider_val.value = clock_div_val.value
    #      it.clock_en.value = 1
    #      it.opcode.value = clock_opcode_e.CLK_DIV
    #    await self.start_item(req)
    #    await self.finish_item(req)
#
    #async def start_clock_phase_shift(self, phase_shift):
    #    req = clock_seq_item("req")
    #    req.randomize()
    #    with req.randomize_with() as it:
    #      it.phase_shift_percent.value = phase_shift.value
    #      it.clock_en.value = 1
    #      it.opcode.value = clock_opcode_e.CLK_SHIFT
    #    await self.start_item(req)
    #    await self.finish_item(req)

    async def initialize_clock(self, reset):
        req = clock_seq_item("req")
        req.randomize()
        with req.randomize_with() as it:
            it.reset_val = reset
            it.clock_en = 1
            it.opcode = clock_opcode_e.CLK_INIT
        await self.start_item(req)
        await self.finish_item(req)

    async def start_clock(self):
        req = clock_seq_item("req")
        req.randomize()
        with req.randomize_with() as it:
          #it.clock_nominal_freq_Hz = clock_freq
          #it.reset_val = reset
          #it.clock_start_delay_fs = clock_start_delay
          #it.ppm_offset = ppm
          it.clock_en = 0
          it.opcode = clock_opcode_e.CLK_START       
        await self.start_item(req)
        await self.finish_item(req)

    async def enable_clock(self):
        req = clock_seq_item("req")
        req.randomize()
        with req.randomize_with() as it:
          it.clock_en = self.clock_en
          it.reset_val = self.reset_val
          it.opcode = clock_opcode_e.CLK_ENA
        await self.start_item(req)
        await self.finish_item(req)       
         

          
        

class clock_basic_seq(clock_base_seq):
    """
    Basic sequence to initialize and start the clock.
    """
    def __init__(self, name="clock_basic_seq"):
        super().__init__(name)
        self.clock_freq_Hz          = None
        self.reset_val              = None
        self.clock_start_delay_fs   = None
        self.ppm_offset             = None
            
    async def body(self):
        """
        Body task for the basic sequence.
        """
        req = clock_seq_item("req")
        self.clock_freq_Hz = 100_000_000
        # Initialize the clock
        #await self.initialize_clock(0)
        # Start the clock with the given parameters
        await self.start_clock()
        
class clock_enable_seq(clock_base_seq):
    """
    Sequence to enable the clock.
    """
    def __init__(self, name="clock_enable_seq"):
        super().__init__(name)

    async def body(self):
        """
        Body task for the enable sequence.
        """
        req = clock_seq_item("req")
        await self.enable_clock(req)
        
