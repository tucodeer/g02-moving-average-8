# G02 — 8-Point Moving Average Filter

RTL implementation of an 8-point moving average filter for digital signal processing.

## Specification

- Input sample: `ui_in[7:0]`
- Input valid: `uio_in[0]`
- Output average: `uo_out[7:0]`
- Output valid: `uio_out[0]`
- Window size: 8 samples
- Division by 8: right shift by 3 bits

## Architecture

The main implementation uses sliding accumulation:

```text
new_sum = old_sum + new_sample - old_sample
The average is obtained by dividing the accumulated sum by 8:

average = sum >> 3

The design must use sliding accumulation instead of recomputing the sum of all eight samples every cycle.

Verification

The design will be tested with:

Constant sequence
Step sequence
Random sequence
Manual reference comparison
Accumulator overflow test
Timing Comparison

The project will compare two architectures:

Sliding accumulation
Recomputing the sum of eight samples

The main comparison will focus on:

Critical path
Logic depth
Area
Timing slack
Project Structure
rtl/        RTL source code
tb/         Testbench
sim/        Simulation scripts and waveforms
synth/      Synthesis files and reports
sta/        Static timing analysis
openlane/   ASIC implementation flow
results/    Important results
docs/       Documentation and report
