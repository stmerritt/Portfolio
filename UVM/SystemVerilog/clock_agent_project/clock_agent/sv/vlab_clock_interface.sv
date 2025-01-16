/// Clock Interface

interface vlab_clock_interface (input bit clock_in);
    bit clock_pass_thru;
    bit clock_out;
    bit clock_en;

    assign clock_pass_thru = clock_in;
endinterface : vlab_clock_interface
