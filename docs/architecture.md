# G02 — 8-Point Moving Average Filter Architecture

## 1. Main Architecture

The main design uses a sliding accumulation architecture.

The filter maintains:

* An 8-sample storage buffer
* A running accumulated sum
* A pointer or control mechanism to identify the oldest sample
* Valid-sample tracking logic
* Division-by-8 logic implemented as a right shift by 3 bits

The conceptual data path is:

```text
                    ┌──────────────────┐
ui_in ─────────────►│  Sample Buffer   │
                    └────────┬─────────┘
                             │
                       old sample
                             │
                             ▼
                    ┌──────────────────┐
                    │   Subtraction    │
                    │ sum - old_sample │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
ui_in ─────────────►│    Addition      │
                    │ + new_sample     │
                    └────────┬─────────┘
                             │
                             ▼
                         new_sum
                             │
                             ▼
                         >> 3
                             │
                             ▼
                          average
```

## 2. Sliding Update

For every valid input sample, the running sum is updated according to:

`new_sum = old_sum + new_sample - old_sample`

The oldest sample is removed from the accumulated sum before the newest sample is added.

This avoids adding all eight samples again on every valid cycle.

## 3. Sample Buffer

The design requires storage for the previous eight input samples.

Conceptually:

```text
sample[0]
sample[1]
sample[2]
sample[3]
sample[4]
sample[5]
sample[6]
sample[7]
```

The storage is updated when a valid input sample arrives.

The sample that has remained in the buffer the longest is used as the value to subtract from the running sum.

## 4. Accumulator Width

The input sample is 8 bits wide.

The maximum possible sum of eight samples is:

`8 × 255 = 2040`

Therefore, the accumulator requires at least 11 bits.

The implementation will use an accumulator width that prevents overflow during addition and subtraction.

## 5. Division by Eight

Because the window contains eight samples, division by eight can be implemented using a right shift:

`average = sum >> 3`

This avoids using a general-purpose divider.

## 6. Valid Control

The input valid signal controls when the filter accepts a new sample.

```text
uio_in[0] = 1
        │
        ▼
Accept sample
        │
        ├── update buffer
        ├── update accumulated sum
        └── update output
```

When the input valid signal is low, the filter state does not advance.

## 7. Initialization

After reset, sample_count = 0 and out_valid = 0.

For each valid input sample:

- sample_count is incremented until eight valid samples have been received;
- samples 1–7 do not produce a valid output;
- sample 8 produces the first valid average;
- from sample 8 onward, out_valid remains asserted for every valid input sample.

## 8. Comparison Architecture

A second implementation will intentionally recompute the sum of all eight stored samples:

```text
sample[0] ─┐
sample[1] ─┤
sample[2] ─┤
sample[3] ─┤
sample[4] ─┤──► Adder network ──► >> 3
sample[5] ─┤
sample[6] ─┤
sample[7] ─┘
```

This implementation is used only as a reference architecture for timing and area comparison.

## 9. Timing Analysis Objective

The main analysis will compare the critical path of:

### Sliding accumulation

```text
old sum → subtraction → addition → shift
```

### Full recomputation

```text
8 samples → adder network → shift
```

The actual critical path will be determined using synthesis and static timing analysis rather than assumed only from the RTL description.
