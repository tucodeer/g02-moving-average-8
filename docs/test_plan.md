# G02 — 8-Point Moving Average Filter Test Plan

## 1. Verification Objective

The testbench verifies that the moving average filter:

* accepts valid input samples correctly;
* maintains the correct eight-sample window;
* updates the sliding accumulation correctly;
* produces the correct average;
* generates the output valid signal correctly;
* does not overflow the accumulator.

## 2. Test Case 1 — Constant Sequence

Apply a constant input value repeatedly.

Example:

```text
10, 10, 10, 10, 10, 10, 10, 10, ...
```

Expected moving average:

```text
10
```

This test verifies the basic steady-state behavior.

## 3. Test Case 2 — Step Sequence

Apply a sequence containing a sudden change.

Example:

```text
0, 0, 0, 0, 0, 0, 0, 0,
255, 255, 255, 255, ...
```

The output should change gradually as the new samples enter the eight-sample window.

This test verifies that old samples are removed correctly while new samples are added.

## 4. Test Case 3 — Sequential / Ramp Sequence

Apply an increasing sequence.

Example:

```text
1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ...
```

The expected result is calculated from the most recent eight valid samples.

This test helps verify the sliding-window behavior.

## 5. Test Case 4 — Random Sequence

Generate random 8-bit input samples.

The RTL output is compared against a reference model.

The reference model calculates the expected average from the latest eight valid samples.

## 6. Test Case 5 — Maximum Value / Overflow Test

Apply the maximum input value:

```text
255
```

for at least eight valid samples.

The maximum accumulated sum should be:

```text
8 × 255 = 2040
```

The test verifies that the accumulator can represent this value without overflow.

## 7. Test Case 6 — Invalid Samples

Insert cycles where:

```text
uio_in[0] = 0
```

The filter must not accept those samples as new window entries.

The internal state and valid output behavior must remain consistent with the specification.

## 8. Reference Model

The testbench will maintain a software/reference window containing the most recent valid samples.

For a full eight-sample window:

```text
expected_sum =
    sample[0] +
    sample[1] +
    ...
    sample[7]

expected_average = expected_sum >> 3
```

The RTL output will be compared against this reference value.

## 9. Timing of Output Validation

The testbench must account for the pipeline/control latency of the RTL implementation.

The output is checked only when the output valid signal indicates that the result is valid.

## 10. Pass Criteria

A test passes when:

1. All expected output values match.
2. Output valid is asserted at the expected time.
3. Invalid input samples do not incorrectly modify the filter state.
4. No accumulator overflow occurs.
5. All planned test cases complete successfully.
