# G02 — 8-Point Moving Average Filter Architecture

# G02 — Kiến trúc bộ lọc trung bình trượt 8 điểm

---

## 1. Main Architecture — Kiến trúc chính

### English

The main design uses a sliding accumulation architecture.

The filter maintains:

* An 8-sample storage buffer
* A running accumulated sum
* A pointer or control mechanism to identify the oldest sample
* Valid-sample tracking logic
* Division-by-8 logic implemented as a right shift by 3 bits

### Tiếng Việt

Thiết kế chính sử dụng kiến trúc tích lũy trượt.

Bộ lọc duy trì:

* Bộ đệm lưu trữ 8 mẫu
* Tổng tích lũy được cập nhật liên tục
* Con trỏ hoặc logic điều khiển để xác định mẫu cũ nhất
* Logic theo dõi số lượng mẫu hợp lệ
* Logic chia cho 8 bằng phép dịch phải 3 bit

The conceptual data path is:

Đường đi dữ liệu về mặt khái niệm:

```text
                    ┌──────────────────┐
ui_in ─────────────►│  Sample Buffer   │
                    │    Bộ đệm mẫu    │
                    └────────┬─────────┘
                             │
                       old sample
                       mẫu cũ nhất
                             │
                             ▼
                    ┌──────────────────┐
                    │   Subtraction    │
                    │ sum - old_sample │
                    │    Trừ mẫu cũ     │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
ui_in ─────────────►│    Addition      │
                    │ + new_sample     │
                    │    Cộng mẫu mới   │
                    └────────┬─────────┘
                             │
                             ▼
                         new_sum
                        tổng mới
                             │
                             ▼
                         >> 3
                             │
                             ▼
                          average
                       giá trị trung bình
```

---

## 2. Sliding Update — Cập nhật tích lũy trượt

For every valid input sample, the running sum is updated according to:

Với mỗi mẫu đầu vào hợp lệ, tổng tích lũy được cập nhật theo:

`new_sum = old_sum + new_sample - old_sample`

The oldest sample is removed from the accumulated sum before the newest sample is added.

Mẫu cũ nhất được loại khỏi tổng tích lũy trước khi mẫu mới nhất được cộng vào.

This avoids adding all eight samples again on every valid cycle.

Cách này tránh phải cộng lại cả tám mẫu trong mỗi chu kỳ có dữ liệu hợp lệ.

---

## 3. Sample Buffer — Bộ đệm mẫu

The design requires storage for the previous eight input samples.

Thiết kế cần lưu trữ tám mẫu đầu vào gần nhất.

Conceptually:

Về mặt khái niệm:

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

Bộ nhớ được cập nhật khi một mẫu đầu vào hợp lệ được nhận.

The sample that has remained in the buffer the longest is used as the value to subtract from the running sum.

Mẫu đã nằm trong bộ đệm lâu nhất được sử dụng làm mẫu cũ để trừ khỏi tổng tích lũy.

---

## 4. Accumulator Width — Độ rộng bộ tích lũy

The input sample is 8 bits wide.

Mẫu đầu vào có độ rộng 8 bit.

The maximum possible sum of eight samples is:

Tổng lớn nhất có thể của tám mẫu là:

`8 × 255 = 2040`

Therefore, the accumulator requires at least 11 bits.

Do đó, bộ tích lũy cần tối thiểu 11 bit.

The implementation uses an 11-bit accumulator to represent the required range without overflow.

Triển khai sử dụng bộ tích lũy 11 bit để biểu diễn phạm vi yêu cầu mà không xảy ra tràn số.

---

## 5. Division by Eight — Phép chia cho tám

Because the window contains eight samples, division by eight can be implemented using a right shift:

Do cửa sổ chứa tám mẫu nên phép chia cho tám có thể được thực hiện bằng phép dịch phải:

`average = sum >> 3`

This avoids using a general-purpose divider.

Cách này tránh phải sử dụng một mạch chia tổng quát.

---

## 6. Valid Control — Điều khiển tín hiệu hợp lệ

The input valid signal controls when the filter accepts a new sample.

Tín hiệu input valid điều khiển thời điểm bộ lọc tiếp nhận mẫu mới.

```text
uio_in[0] = 1
        │
        ▼
Accept sample
Nhận mẫu
        │
        ├── update buffer
        │   cập nhật bộ đệm
        │
        ├── update accumulated sum
        │   cập nhật tổng tích lũy
        │
        └── update output
            cập nhật đầu ra
```

When the input valid signal is low, the filter state does not advance.

Khi tín hiệu input valid ở mức thấp, trạng thái của bộ lọc không được cập nhật.

---

## 7. Initialization — Khởi tạo

After reset, `sample_count = 0` and `out_valid = 0`.

Sau reset, `sample_count = 0` và `out_valid = 0`.

For each valid input sample:

Với mỗi mẫu đầu vào hợp lệ:

* `sample_count` is incremented until the window is full.
* `sample_count` được tăng cho đến khi cửa sổ đầy.
* Samples 1–7 do not produce a valid output.
* Các mẫu 1–7 chưa tạo ra đầu ra hợp lệ.
* Sample 8 produces the first valid average.
* Mẫu thứ 8 tạo ra giá trị trung bình hợp lệ đầu tiên.
* From sample 8 onward, `out_valid` is asserted whenever a valid sample updates the window.
* Từ mẫu thứ 8 trở đi, `out_valid` được xác nhận khi một mẫu hợp lệ cập nhật cửa sổ.

---

## 8. Comparison Architecture — Kiến trúc dùng để so sánh

A second implementation will intentionally recompute the sum of all eight stored samples.

Một triển khai thứ hai được xây dựng để cố ý tính lại tổng của cả tám mẫu đã lưu:

```text
sample[0] ─┐
sample[1] ─┤
sample[2] ─┤
sample[3] ─┤
sample[4] ─┤──► Adder network ──► >> 3
sample[5] ─┤      Mạng cộng
sample[6] ─┤
sample[7] ─┘
```

This implementation is used only as a reference architecture for timing and area comparison.

Triển khai này chỉ được sử dụng làm kiến trúc tham chiếu để so sánh diện tích và timing.

---

## 9. Timing Analysis Objective — Mục tiêu phân tích timing

The comparison initially considers the following logical operations:

### Sliding accumulation — Tích lũy trượt

```text
old sum → subtraction → addition → shift
tổng cũ → phép trừ → phép cộng → dịch phải
```

### Full recomputation — Tính lại toàn bộ

```text
8 samples → adder network → shift
8 mẫu → mạng cộng → dịch phải
```

However, the actual critical path is determined from synthesis and static timing analysis rather than assumed solely from the RTL description.

Tuy nhiên, đường tới hạn thực tế được xác định từ kết quả tổng hợp và phân tích timing tĩnh (STA), thay vì chỉ suy đoán dựa trên mô tả RTL.

This distinction is important because control logic, multiplexers, routing, fanout, and other implementation effects can determine the final critical path.

Điều này quan trọng vì logic điều khiển, bộ chọn dữ liệu, routing, fanout và các yếu tố của quá trình triển khai có thể quyết định đường tới hạn thực tế.
