# G02 — 8-Point Moving Average Filter Specification

## 1. Overview

This project implements an 8-point moving average filter using RTL design.

The filter processes an input sequence of 8-bit samples and produces the average value of the most recent eight valid samples.

The main implementation must use a **sliding accumulation** technique instead of recomputing the sum of all eight samples every cycle.

## 2. Interface

| Signal       | Direction |  Width | Description           |
| ------------ | --------- | -----: | --------------------- |
| `ui_in`      | Input     | 8 bits | Input sample          |
| `uio_in[0]`  | Input     |  1 bit | Input sample valid    |
| `uo_out`     | Output    | 8 bits | Moving average result |
| `uio_out[0]` | Output    |  1 bit | Output result valid   |

Other interface signals are not used by the functional design.

## 3. Filter Parameters

* Input sample width: 8 bits
* Number of samples in the moving window: 8
* Window size: 8 samples
* Division factor: 8
* Division implementation: right shift by 3 bits

For a window containing:

`x[n-7], x[n-6], ..., x[n]`

the output is:

`y[n] = (x[n-7] + x[n-6] + ... + x[n]) / 8`

The division by 8 is implemented as a shift right by 3 bits.

## 4. Sliding Accumulation Requirement

The main implementation must update the accumulated sum by adding the newest sample and subtracting the oldest sample:

`new_sum = old_sum + new_sample - old_sample`

The design must not recompute the sum of all eight samples every valid cycle.

A storage structure is therefore required to retain the previous eight samples or otherwise provide access to the oldest sample.

## 5. Valid Signal

A new sample is accepted only when:

`uio_in[0] = 1`

When `uio_in[0] = 0`, the input sample is not considered a new valid sample and the filter state must not advance.

The output valid signal `uio_out[0]` indicates when `uo_out` contains a valid moving-average result.

## 6. Initialization and Output Valid Behavior

After reset, all internal sample storage, the accumulator, output data, and output valid signal are cleared.

The filter requires eight valid input samples before producing the first valid moving-average result.

### Samples 1–7

For each valid input sample:

* The sample is stored in the sample buffer.
* The accumulated sum is updated.
* The sample counter is incremented.
* `uo_out` remains `0`.
* `uio_out[0]` remains `0`.

Therefore, the first seven samples do not produce a valid output.

### Sample 8

When the eighth valid sample is received:

* The eight-sample window becomes full.
* The accumulated sum represents the sum of the eight valid samples.
* The average is calculated using a right shift by 3 bits.
* The result is written to `uo_out`.
* `uio_out[0]` is asserted to `1`.

### Sample 9 and Later

For every subsequent valid sample:

1. The oldest sample is removed from the window.
2. The newest sample is inserted into the window.
3. The running sum is updated using:

`new_sum = old_sum - oldest_sample + newest_sample`

4. The new average is calculated using:

`average = new_sum >> 3`

5. `uio_out[0]` remains asserted.

Invalid input cycles (`uio_in[0] = 0`) do not advance the sample window or modify the filter state.

## 7. Reset Behavior

The active-low reset signal `rst_n` clears:

* all eight sample storage elements;
* the accumulator;
* the sample counter;
* `uo_out`;
* `uio_out[0]`.

After reset:

```text
accumulator = 0
sample_count = 0
uo_out = 0
uio_out[0] = 0
```

## 8. Internal Data Width

The input sample width is 8 bits.

The maximum sum of eight 8-bit unsigned samples is:

`8 × 255 = 2040`

Therefore, the accumulator must be at least 11 bits wide.

The sample counter must represent values from 0 through 8 and therefore requires 4 bits.

## 9. Output Interface Mapping

The logical signals are mapped directly onto the required project interface:

```text
uo_out[7:0]  = out_data
uio_out[0]   = out_valid
```

No additional external output port is required.


## 10. Target Flow

The project is intended to follow the RTL-to-ASIC flow:

`RTL → Simulation → Synthesis → STA → OpenLane`

The synthesis and timing results will be documented after the corresponding flows are completed.
