This project seeks to create a clock agent capable of generating a clock signal with defined frequency, having multiple modes of operation (Standard, Clock Divider, Phase Shift).

In all modes, a pass_thru clock is available that is equivalent to the input clock. In Standard mode, the input clock is optional. Clock Divider and Phase Shift modes require an input clock.

In Standard mode, the user defines clock_nominal_frequency_Hz, clock_start_delay_fs, reset_val, and ppm_offset. Reset_val is defined as the expected output value when the clock agent is disabled. Implicitly, reset_val is also the opposite of the expected first pulse of an active clock. The clock agent generates this clock signal when active.

In Clock Divider mode, the user defines clock_divider_val. The clock agent reads an input clock and produces an output clock with slower frequency as determined by clock_divider_val. This clock is in sync with the input clock. Duty cycle of the input clock is not preserved.

In Phase Shift mode, the user defines phase_shift_percent. The clock agent reads the input clock period and produces an output clock that is phase_shift_percent behind the input clock. The input and output clocks have the same frequency. Duty cycle of the input clock is preserved.

[![vlab_clock_agent drawing](img/vlab_clock_agent.drawio.png 'vlab_clock_agent')]