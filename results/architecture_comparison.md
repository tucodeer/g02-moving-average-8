# G02 - Architecture Comparison

# G02 - So sánh kiến trúc

## Sliding Accumulation vs Recompute

## Tích lũy trượt và tính lại toàn bộ

| Metric / Chỉ số     | Sliding Accumulation / Tích lũy trượt | Recompute / Tính lại |
| ------------------- | ------------------------------------: | -------------------: |
| Sky130 cells        |                                   389 |                  490 |
| Flip-flops          |                                    91 |                   80 |
| Combinational cells |                                   298 |                  410 |
| Worst path arrival  |                              5.172 ns |             6.363 ns |
| Estimated Tmin      |                             ~5.341 ns |            ~6.485 ns |
| Estimated Fmax      |                            ~187.2 MHz |           ~154.2 MHz |

> **Note / Lưu ý:** The cell counts above are synthesis results for the Sky130-mapped netlists. They should not be directly compared with the final OpenLane physical instance count, which also includes physical implementation cells such as fill, tap, and clock-related cells.
>
> Các số lượng cell ở trên là kết quả tổng hợp của netlist đã ánh xạ sang Sky130. Không nên so sánh trực tiếp các giá trị này với tổng số instance của thiết kế sau OpenLane, vì kết quả triển khai vật lý còn bao gồm các cell phục vụ physical design như fill, tap và clock-related cells.

---

## 1. Architecture Principle — Nguyên lý kiến trúc

### English

The sliding accumulation architecture maintains a running sum of the eight samples in the current window.

For each new valid sample:

`new_sum = old_sum - oldest_sample + newest_sample`

Only the oldest sample and the newest sample are involved in updating the running sum.

### Tiếng Việt

Kiến trúc tích lũy trượt duy trì tổng của tám mẫu đang nằm trong cửa sổ hiện tại.

Với mỗi mẫu mới hợp lệ:

`new_sum = old_sum - oldest_sample + newest_sample`

Chỉ mẫu cũ nhất và mẫu mới nhất được sử dụng để cập nhật tổng tích lũy.

---

## 2. Recompute Architecture — Kiến trúc tính lại

### English

The recompute architecture calculates the sum of all eight stored samples for each valid update.

This requires an adder network that combines all eight samples before the division-by-8 operation.

### Tiếng Việt

Kiến trúc tính lại thực hiện phép cộng của cả tám mẫu được lưu trữ ở mỗi lần cập nhật hợp lệ.

Điều này yêu cầu một mạng các bộ cộng để kết hợp cả tám mẫu trước khi thực hiện phép chia cho 8.

---

## 3. Synthesis Comparison — So sánh sau tổng hợp

### English

In this synthesis experiment, the recompute architecture required more combinational logic than the sliding accumulation architecture.

The number of Sky130 cells increased from 389 cells for the sliding implementation to 490 cells for the recompute implementation.

The recompute implementation therefore used 101 more mapped cells in this experiment.

### Tiếng Việt

Trong thí nghiệm tổng hợp này, kiến trúc tính lại yêu cầu nhiều logic tổ hợp hơn so với kiến trúc tích lũy trượt.

Số lượng cell Sky130 tăng từ 389 cell đối với kiến trúc tích lũy trượt lên 490 cell đối với kiến trúc tính lại.

Như vậy, trong thí nghiệm này, kiến trúc tính lại sử dụng nhiều hơn 101 cell sau quá trình mapping.

---

## 4. Timing Comparison — So sánh timing

### English

The reported worst path arrival time was 5.172 ns for the sliding architecture and 6.363 ns for the recompute architecture.

Using the specified STA constraints, the corresponding estimated minimum clock periods were approximately 5.341 ns and 6.485 ns.

The estimated maximum frequencies were approximately:

* Sliding accumulation: ~187.2 MHz
* Recompute: ~154.2 MHz

### Tiếng Việt

Thời gian đến của đường timing được báo cáo là 5.172 ns đối với kiến trúc tích lũy trượt và 6.363 ns đối với kiến trúc tính lại.

Với các ràng buộc STA đã sử dụng, chu kỳ clock tối thiểu ước tính tương ứng là khoảng 5.341 ns và 6.485 ns.

Tần số tối đa ước tính tương ứng là:

* Tích lũy trượt: ~187.2 MHz
* Tính lại: ~154.2 MHz

---

## 5. Observation — Nhận xét

### English

In this synthesis experiment, the recompute architecture required more combinational logic and had a longer worst reported synchronous path.

Cell count increased from 389 to 490 cells, while the reported path arrival time increased from 5.172 ns to 6.363 ns.

The estimated maximum frequency was approximately 187.2 MHz for the sliding architecture and 154.2 MHz for the recompute architecture.

These results indicate that, for this implementation and under the specified synthesis/STA conditions, the sliding accumulation architecture has lower mapped cell count and shorter reported timing paths.

### Tiếng Việt

Trong thí nghiệm tổng hợp này, kiến trúc tính lại yêu cầu nhiều logic tổ hợp hơn và có đường timing đồng bộ được báo cáo dài hơn.

Số lượng cell tăng từ 389 lên 490, trong khi thời gian đến của đường timing được báo cáo tăng từ 5.172 ns lên 6.363 ns.

Tần số tối đa ước tính là khoảng 187.2 MHz đối với kiến trúc tích lũy trượt và 154.2 MHz đối với kiến trúc tính lại.

Các kết quả này cho thấy rằng, **đối với triển khai cụ thể và các điều kiện synthesis/STA đã sử dụng**, kiến trúc tích lũy trượt có số lượng cell sau mapping thấp hơn và đường timing được báo cáo ngắn hơn.

---

## 6. Important Timing Note — Lưu ý quan trọng về timing

### English

The timing values in this comparison are based on synthesized Sky130 netlists and the specified STA constraints.

They are therefore **pre-layout timing results**, not final post-route timing results.

The actual post-route critical path can be different because placement, routing, parasitic capacitance, fanout, buffering, and control logic can affect the final timing.

### Tiếng Việt

Các giá trị timing trong phép so sánh này được lấy từ netlist Sky130 sau tổng hợp và các ràng buộc STA đã chỉ định.

Do đó, đây là **kết quả timing trước layout**, không phải kết quả timing cuối cùng sau routing.

Đường tới hạn sau routing thực tế có thể khác do placement, routing, điện dung ký sinh, fanout, buffering và logic điều khiển có thể ảnh hưởng đến timing cuối cùng.
