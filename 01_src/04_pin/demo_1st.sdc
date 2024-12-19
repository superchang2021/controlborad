create_clock -name sys_clk_50m -period 20 -waveform {0 10} [get_ports {sys_clk_in}]
derive_pll_clocks