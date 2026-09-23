# G02 - Architecture Comparison

## Sliding Accumulation vs Recompute

| Metric | Sliding Accumulation | Recompute |
|---|---:|---:|
| Sky130 cells | 389 | 490 |
| Flip-flops | 91 | 80 |
| Combinational cells | 298 | 410 |
| Worst path arrival | 5.172 ns | 6.363 ns |
| Estimated Tmin | ~5.341 ns | ~6.485 ns |
| Estimated Fmax | ~187.2 MHz | ~154.2 MHz |

## Observation

The sliding accumulation architecture uses a running sum:

    new_sum = old_sum - oldest_sample + newest_sample

The recompute architecture calculates the window sum from the stored
eight samples for each update.

In this synthesis experiment, the recompute architecture required
more combinational logic and had a longer worst reported synchronous
path.

Cell count increased from 389 to 490 cells, while the reported path
arrival time increased from 5.172 ns to 6.363 ns.

The estimated maximum frequency was approximately 187.2 MHz for the
sliding architecture and 154.2 MHz for the recompute architecture.

These results are based on synthesized Sky130 netlists and the
specified STA constraints. They should be treated as pre-layout
timing results rather than final post-route timing.
