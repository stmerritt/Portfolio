from clock_uvc import *

class clock_monitor(uvm_monitor):
    """
    Clock Monitor for clock agent
    """
    def __init__(self, name="clock_monitor", parent=None):
        super().__init__(name, parent)
        self.cfg_item = None  # Configuration item
        
    def build_phase(self):
        
        """
        Build phase to initialize components and configuration
        """
        super().build_phase()
        
        self.mon_ap = uvm_analysis_port("mon_ap", self)


    def connect_phase(self):
        self.logger.debug("Entered Monitor's Connect Phase")
        prefix = ""
        self.clock_out =   getattr(cocotb.top, (prefix + "clk"))
        self.clock_in  =   getattr(cocotb.top, (prefix + "clk"))
        self.reset     =   getattr(cocotb.top, (prefix + "reset"))
        
        #self.clock_pass_thru = getattr(cocotb.top, (prefix + "clock_pass_thru"))
        #self.clock_out = getattr(cocotb.top, (prefix + "clock_out"))
        #self.clock_en = getattr(cocotb.top, (prefix + "clock_en"))
        #self.clock_in = getattr(cocotb.top, (prefix + "clock_in")) 
        self.logger.debug("Entered Monitor's Connect Phase")

    async def run_phase(self):
        """
        Monitor the clock interface and write observations to the analysis port
        """
        while True:
            mon_item = None
            await cocotb.start_soon(self.capture_signal("clock_out", clock_opcode_e.CLK_START, posedge=True))

            # Concurrent tasks to monitor signals
            #self.clock_en = cocotb.start_soon(self.capture_signal("clock_en", clock_opcode_e.CLK_ENA))
            #self.clock_out = cocotb.start_soon(self.capture_signal("clock_out", clock_opcode_e.CLK_START, posedge=True))
            #self.clock_in = cocotb.start_soon(self.capture_signal("clock_in", clock_opcode_e.CLK_INPUT, posedge=True))
            #await Combine(self.clock_en, self.clock_in, self.clock_out)
            
    async def capture_signal(self, signal_name, opcode, posedge=False):
        """
        Capture signal changes and write observations to the analysis port.
        :param signal_name: Name of the signal in the interface
        :param opcode: Opcode to identify the signal type
        :param posedge: Whether to capture positive edges only (True/False)
        """
        while True:
            if posedge:
                await cocotb.triggers.RisingEdge(getattr(self, signal_name))
            else:
                await cocotb.triggers.Edge(getattr(self, signal_name))

            self.write_mon_item(opcode)

    def write_mon_item(self, opcode):
        """
        Create and send a monitored item.
        :param opcode: Opcode to identify the type of observation
        """
        mon_item = clock_seq_item()
        mon_item.opcode = opcode
        #mon_item.clock_en = self.clock_en
        #mon_item.timestamp = self.get_sim_time('fs')
        self.mon_ap.write(mon_item)

    # Method to for the config from the Reset Agent
    def set_cfg(self, new_cfg_item):
        self.logger.debug("Setting Config Object")        
        self.cfg_item = new_cfg_item
        self.logger.debug(self.cfg_item.convert2string())


#import pyuvm
#from pyuvm import *
#from clock_agent import *
#from clock_cfg_item import *
#from clock_seq_item import *
#
#class clock_monitor(uvm_monitor):
#    """
#    Reset agent monitor
#    """
#    def __init__(self, name="clock_monitor", parent=None):
#        super().__init__(name, parent)
#        #self.cfg_item = None  # Configuration item
#        self.mon_ap = pyuvm.uvm_analysis_port("mon_ap", self)  # Analysis port
#
#    def build_phase(self):
#        super().build_phase()
#
#    def connect_phase(self):
#        self.logger.debug("Entered Monitor's Connect Phase")
#        prefix = ""
#        self.clock_pass_thru = getattr(cocotb.top, (prefix + "clock_pass_thru"))
#        self.clock_out = getattr(cocotb.top, (prefix + "clock_out"))
#        self.clock_en = getattr(cocotb.top, (prefix + "clock_en"))
#        self.clock_in = getattr(cocotb.top, (prefix + "clock_in")) 
#        self.logger.debug("Entered Monitor's Connect Phase")
#
#    async def run_phase(self):
#        self.logger.debug("Entered Monitor's Run Phase")
#
#        # Create an empty clock item
#        clock_item = clock_seq_item()
#
#        while True:
#            # Wait for a change on the clock signal
#            self.logger.debug("self.clock:_out " + f"{self.clock_out.value}")
#            await cocotb.triggers.Edge(self.clock_out)
#            self.logger.debug("self.clock_out: " + f"{self.clock_out.value}")
#
#
#            self.mon_ap.write(clock_item)
#
#    ## Method to for the config from the Reset Agent
#    #def set_cfg(self, new_cfg_item):
#    #    self.logger.debug("Setting Config Object")        
#    #    self.cfg_item = new_cfg_item
#    #    self.logger.debug(self.cfg_item.convert2string())
