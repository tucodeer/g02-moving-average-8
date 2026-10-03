# G02 — 8-Point Moving Average Filter Specification

# G02 — Đặc tả bộ lọc trung bình trượt 8 điểm

---

## 1. Overview — Tổng quan

### English

This project implements an 8-point moving average filter using RTL design.

The filter processes an input sequence of 8-bit samples and produces the average value of the most recent eight valid samples.

The main implementation must use a **sliding accumulation** technique instead of recomputing the sum of all eight samples every cycle.

### Tiếng Việt

Dự án thực hiện một bộ lọc trung bình trượt 8 điểm bằng phương pháp thiết kế RTL.

Bộ lọc nhận vào một chuỗi các mẫu dữ liệu 8 bit và tạo ra giá trị trung bình của **8 mẫu hợp lệ gần nhất**.

Kiến trúc chính phải sử dụng phương pháp **tích lũy trượt (sliding accumulation)** thay vì tính lại tổng của cả 8 mẫu ở mỗi chu kỳ.

---

## 2. Interface — Giao diện

| Signal       | Direction |  Width | English Description   | Mô tả tiếng Việt                        |
| ------------ | --------- | -----: | --------------------- | --------------------------------------- |
| `ui_in`      | Input     | 8 bits | Input sample          | Mẫu dữ liệu đầu vào                     |
| `uio_in[0]`  | Input     |  1 bit | Input sample valid    | Tín hiệu xác nhận mẫu đầu vào hợp lệ    |
| `uo_out`     | Output    | 8 bits | Moving average result | Kết quả trung bình trượt                |
| `uio_out[0]` | Output    |  1 bit | Output result valid   | Tín hiệu xác nhận kết quả đầu ra hợp lệ |

Other interface signals are not used by the functional design.

Các tín hiệu giao diện khác không được sử dụng trong chức năng của thiết kế.

---

## 3. Filter Parameters — Tham số bộ lọc

### English

* Input sample width: 8 bits
* Number of samples in the moving window: 8
* Window size: 8 samples
* Division factor: 8
* Division implementation: right shift by 3 bits

### Tiếng Việt

* Độ rộng mẫu đầu vào: 8 bit
* Số mẫu trong cửa sổ trượt: 8
* Kích thước cửa sổ: 8 mẫu
* Hệ số chia: 8
* Phương pháp chia: dịch phải 3 bit

For a window containing:

Với một cửa sổ chứa:

`x[n-7], x[n-6], ..., x[n]`

the output is:

đầu ra được tính bởi:

`y[n] = (x[n-7] + x[n-6] + ... + x[n]) / 8`

The division by 8 is implemented as a shift right by 3 bits.

Phép chia cho 8 được thực hiện bằng phép dịch phải 3 bit.

---

## 4. Sliding Accumulation Requirement — Yêu cầu về tích lũy trượt

### English

The main implementation must update the accumulated sum by adding the newest sample and subtracting the oldest sample:

`new_sum = old_sum + new_sample - old_sample`

The design must not recompute the sum of all eight samples every valid cycle.

A storage structure is therefore required to retain the previous eight samples or otherwise provide access to the oldest sample.

### Tiếng Việt

Kiến trúc chính phải cập nhật tổng tích lũy bằng cách cộng mẫu mới nhất và trừ mẫu cũ nhất:

`new_sum = old_sum + new_sample - old_sample`

Thiết kế không được tính lại tổng của cả tám mẫu ở mỗi chu kỳ có dữ liệu hợp lệ.

Do đó, thiết kế cần có một cấu trúc lưu trữ tám mẫu trước đó hoặc một cơ chế tương đương để truy cập được mẫu cũ nhất trong cửa sổ.

---

## 5. Valid Signal — Tín hiệu hợp lệ

### English

A new sample is accepted only when:

`uio_in[0] = 1`

When `uio_in[0] = 0`, the input sample is not considered a new valid sample and the filter state must not advance.

The output valid signal `uio_out[0]` indicates when `uo_out` contains a valid moving-average result.

### Tiếng Việt

Một mẫu mới chỉ được bộ lọc tiếp nhận khi:

`uio_in[0] = 1`

Khi `uio_in[0] = 0`, mẫu đầu vào không được xem là một mẫu hợp lệ mới và trạng thái của bộ lọc không được cập nhật.

Tín hiệu `uio_out[0]` cho biết thời điểm giá trị trên `uo_out` chứa một kết quả trung bình trượt hợp lệ.

---

## 6. Initialization and Output Valid Behavior

## Khởi tạo và hoạt động của tín hiệu Output Valid

### English

After reset, all internal sample storage, the accumulator, output data, and output valid signal are cleared.

The filter requires eight valid input samples before producing the first valid moving-average result.

### Tiếng Việt

Sau khi reset, toàn bộ bộ nhớ lưu mẫu, bộ tích lũy, dữ liệu đầu ra và tín hiệu output valid được xóa.

Bộ lọc cần nhận đủ tám mẫu đầu vào hợp lệ trước khi tạo ra kết quả trung bình trượt hợp lệ đầu tiên.

### Samples 1–7 — Các mẫu 1–7

For each valid input sample:

* The sample is stored in the sample buffer.
* The accumulated sum is updated.
* The sample counter is incremented.
* `uo_out` remains `0`.
* `uio_out[0]` remains `0`.

Với mỗi mẫu đầu vào hợp lệ:

* Mẫu được lưu vào bộ đệm.
* Tổng tích lũy được cập nhật.
* Bộ đếm số mẫu được tăng.
* `uo_out` vẫn bằng `0`.
* `uio_out[0]` vẫn bằng `0`.

Therefore, the first seven samples do not produce a valid output.

Do đó, bảy mẫu đầu tiên chưa tạo ra kết quả đầu ra hợp lệ.

### Sample 8 — Mẫu thứ 8

When the eighth valid sample is received:

* The eight-sample window becomes full.
* The accumulated sum represents the sum of the eight valid samples.
* The average is calculated using a right shift by 3 bits.
* The result is written to `uo_out`.
* `uio_out[0]` is asserted to `1`.

Khi nhận được mẫu hợp lệ thứ tám:

* Cửa sổ tám mẫu trở nên đầy.
* Tổng tích lũy biểu diễn tổng của tám mẫu hợp lệ.
* Giá trị trung bình được tính bằng phép dịch phải 3 bit.
* Kết quả được ghi vào `uo_out`.
* `uio_out[0]` được đặt bằng `1`.

### Sample 9 and Later — Mẫu thứ 9 và các mẫu tiếp theo

For every subsequent valid sample:

1. The oldest sample is removed from the window.
2. The newest sample is inserted into the window.
3. The running sum is updated using:

`new_sum = old_sum - oldest_sample + newest_sample`

4. The new average is calculated using:

`average = new_sum >> 3`

5. `uio_out[0]` is asserted.

Với mỗi mẫu hợp lệ tiếp theo:

1. Mẫu cũ nhất được loại khỏi cửa sổ.
2. Mẫu mới nhất được đưa vào cửa sổ.
3. Tổng tích lũy được cập nhật theo:

`new_sum = old_sum - oldest_sample + newest_sample`

4. Giá trị trung bình mới được tính theo:

`average = new_sum >> 3`

5. `uio_out[0]` được đặt bằng `1`.

Invalid input cycles (`uio_in[0] = 0`) do not advance the sample window or modify the filter state.

Các chu kỳ có đầu vào không hợp lệ (`uio_in[0] = 0`) không làm cửa sổ mẫu dịch chuyển và không làm thay đổi trạng thái của bộ lọc.

---

## 7. Reset Behavior — Hoạt động của Reset

### English

The active-low reset signal `rst_n` clears:

* all eight sample storage elements;
* the accumulator;
* the sample counter;
* `uo_out`;
* `uio_out[0]`.

### Tiếng Việt

Tín hiệu reset tác động mức thấp `rst_n` sẽ xóa:

* cả tám phần tử lưu trữ mẫu;
* bộ tích lũy;
* bộ đếm số mẫu;
* `uo_out`;
* `uio_out[0]`.

After reset:

Sau reset:

```text
accumulator = 0
sample_count = 0
uo_out = 0
uio_out[0] = 0
```

---

## 8. Internal Data Width — Độ rộng dữ liệu bên trong

### English

The input sample width is 8 bits.

The maximum sum of eight 8-bit unsigned samples is:

`8 × 255 = 2040`

Therefore, the accumulator must be at least 11 bits wide.

The sample counter must represent values from 0 through 8 and therefore requires 4 bits.

### Tiếng Việt

Độ rộng của mẫu đầu vào là 8 bit.

Tổng lớn nhất của tám mẫu không dấu 8 bit là:

`8 × 255 = 2040`

Do đó, bộ tích lũy phải có độ rộng tối thiểu 11 bit.

Bộ đếm số mẫu cần biểu diễn các giá trị từ 0 đến 8, do đó cần 4 bit.

---

## 9. Output Interface Mapping — Ánh xạ giao diện đầu ra

The logical signals are mapped directly onto the required project interface.

Các tín hiệu logic được ánh xạ trực tiếp vào giao diện yêu cầu của dự án:

```text
uo_out[7:0]  = out_data
uio_out[0]   = out_valid
```

No additional external output port is required.

Không yêu cầu thêm cổng đầu ra bên ngoài nào khác.

---

## 10. Target Flow — Flow thiết kế mục tiêu

### English

The project follows the following RTL-to-ASIC flow:

`RTL → Simulation → Synthesis → STA → OpenLane`

The synthesis, timing, and physical-design results are documented separately in the `results/` directory.

### Tiếng Việt

Dự án thực hiện theo flow RTL-to-ASIC:

`RTL → Simulation → Synthesis → STA → OpenLane`

Các kết quả tổng hợp logic, phân tích timing và triển khai vật lý được ghi lại riêng trong thư mục `results/`.
