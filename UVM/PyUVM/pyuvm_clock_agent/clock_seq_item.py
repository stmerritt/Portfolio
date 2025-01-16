from clock_uvc import *

@enum.unique
class clock_opcode_e(Enum):
    CLK_INIT  = 0
    CLK_ENA   = 1
    CLK_START = 2
    CLK_DIV   = 3
    CLK_SHIFT = 4

@vsc.randobj
@add_objprint
class clock_seq_item(uvm_sequence_item):
  """
  Sequence item for clock agent
  """
  def __init__(self, name="clock_seq_item"):
      super().__init__(name)
      # Initialize with default values as in SystemVerilog constraints
      self.opcode                   = clock_opcode_e.CLK_INIT
      self.timestamp                = None

      self.clock_en                = None

      
  def __repr__(self):
      return str(self.__class__) + '\n'+ '\n'.join(('{} \t\t= {}'.format(item, self.__dict__[item]) for item in self.__dict__))
     
  #def __str__(self):
  #    return f'clock_seq_item: \n\topcode    {self.opcode} \n\tclock_nominal_freq_Hz    {self.clock_nominal_freq_Hz} \n\tclock_start_delay_fs    {self.clock_start_delay_fs}'
   

