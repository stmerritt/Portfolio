from clock_uvc import *

# Reset Agent Class
class clock_agent(uvm_agent):
    """
    Agent to drive a clock of a DUT.
    """
    
    def __init__(self, name="clock_agent", parent=None):
        super().__init__(name, parent)
        self.mon = None
        self.drv = None
        self.sqr = None
        self.cfg_item = None
        self.is_active = uvm_active_passive_enum.UVM_ACTIVE  # By default, the agent is active

    def build_phase(self):
        # Create the monitor        
        self.mon = clock_monitor("mon", self)
                # get config from test
        self.cfg_item = ConfigDB().get(self, "", "cfg_item")
        # Create the monitor        
        self.mon.set_cfg(self.cfg_item)
               
        # Log the state of is_active
        self.logger.debug("is_active = " + f"{self.is_active}")

        # If the agent is active, create the driver and sequencer
        if self.is_active == uvm_active_passive_enum.UVM_ACTIVE:
            self.logger.debug("Creating driver and sequencer")
            self.drv = clock_driver.create("drv", self)
            self.drv.set_cfg(self.cfg_item)            
            self.sqr = uvm_sequencer.create("sqr", self)
        else:
            self.logger.debug("Not creating driver and sequencer")

    def connect_phase(self):
        # Connect driver to sequencer if the agent is active
        if self.is_active == uvm_active_passive_enum.UVM_ACTIVE:
            self.drv.seq_item_port.connect(self.sqr.seq_item_export)

