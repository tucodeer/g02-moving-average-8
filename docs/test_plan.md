# G02 — 8-Point Moving Average Filter Test Plan

# G02 — Kế hoạch kiểm thử bộ lọc trung bình trượt 8 điểm

---

## 1. Verification Objective — Mục tiêu kiểm thử

### English

The testbench verifies that the moving average filter:

* accepts valid input samples correctly;
* maintains the correct eight-sample window;
* updates the sliding accumulation correctly;
* produces the correct average;
* generates the output valid signal correctly;
* does not overflow the accumulator;
* ignores invalid input cycles;
* correctly handles reset during operation.

### Tiếng Việt

Testbench kiểm tra rằng bộ lọc trung bình trượt:

* tiếp nhận đúng các mẫu đầu vào hợp lệ;
* duy trì đúng cửa sổ gồm tám mẫu;
* cập nhật đúng tổng tích lũy trượt;
* tạo ra giá trị trung bình chính xác;
* tạo tín hiệu output valid đúng thời điểm;
* không xảy ra tràn bộ tích lũy;
* bỏ qua các chu kỳ có đầu vào không hợp lệ;
* xử lý đúng reset trong khi mạch đang hoạt động.

---

## 2. Test Case 1 — Basic Window Fill

## Kiểm thử 1 — Điền đầy cửa sổ

Apply a sequence of valid samples and verify that no valid output is generated until the eighth valid sample.

Đưa vào một chuỗi các mẫu hợp lệ và kiểm tra rằng chưa có kết quả hợp lệ nào được tạo ra cho đến khi nhận đủ mẫu hợp lệ thứ tám.

Example:

```text
1, 2, 3, 4, 5, 6, 7, 8
```

Expected average:

```text
(1 + 2 + 3 + 4 + 5 + 6 + 7 + 8) / 8 = 4
```

Expected behavior:

```text
Samples 1–7: out_valid = 0
Sample 8:     out_valid = 1, average = 4
```

---

## 3. Test Case 2 — Sliding Window

## Kiểm thử 2 — Cửa sổ trượt

After the first eight valid samples, apply additional samples and verify that the oldest sample is removed while the newest sample is added.

Sau tám mẫu hợp lệ đầu tiên, tiếp tục đưa thêm mẫu mới và kiểm tra rằng mẫu cũ nhất được loại bỏ trong khi mẫu mới nhất được thêm vào.

Example:

```text
1, 2, 3, 4, 5, 6, 7, 8, 9
```

For sample 9, the expected window is:

```text
2, 3, 4, 5, 6, 7, 8, 9
```

Expected average:

```text
48 / 8 = 6
```

This verifies the sliding accumulation operation.

Kiểm thử này xác nhận hoạt động của cơ chế tích lũy trượt.

---

## 4. Test Case 3 — Constant Sequence

## Kiểm thử 3 — Chuỗi hằng

Apply a constant input value repeatedly.

Đưa vào một giá trị không đổi trong nhiều chu kỳ hợp lệ.

Example:

```text
10, 10, 10, 10, 10, 10, 10, 10, ...
```

Expected moving average:

```text
10
```

This test verifies steady-state behavior.

Kiểm thử này xác nhận hoạt động ổn định của bộ lọc.

---

## 5. Test Case 4 — Step Sequence

## Kiểm thử 4 — Chuỗi bước

Apply a sequence containing a sudden change.

Đưa vào một chuỗi có sự thay đổi đột ngột.

Example:

```text
0, 0, 0, 0, 0, 0, 0, 0,
255, 255, 255, 255, ...
```

The output should change gradually as the new samples enter the eight-sample window.

Kết quả đầu ra phải thay đổi dần khi các mẫu mới lần lượt đi vào cửa sổ tám mẫu.

This test verifies that old samples are removed correctly while new samples are added.

Kiểm thử này xác nhận rằng mẫu cũ được loại bỏ và mẫu mới được thêm vào đúng cách.

---

## 6. Test Case 5 — Random Sequence

## Kiểm thử 5 — Chuỗi ngẫu nhiên

Generate random 8-bit input samples.

Sinh các mẫu đầu vào 8 bit ngẫu nhiên.

The RTL output is compared against a reference model.

Kết quả RTL được so sánh với một mô hình tham chiếu.

The reference model calculates the expected average from the latest eight valid samples.

Mô hình tham chiếu tính giá trị trung bình dự kiến từ tám mẫu hợp lệ gần nhất.

---

## 7. Test Case 6 — Maximum Value / Overflow Test

## Kiểm thử 6 — Giá trị cực đại / kiểm tra tràn

Apply the maximum input value:

Đưa vào giá trị đầu vào lớn nhất:

```text
255
```

for at least eight valid samples.

trong ít nhất tám mẫu hợp lệ.

The maximum accumulated sum should be:

Tổng tích lũy lớn nhất là:

```text
8 × 255 = 2040
```

The test verifies that the accumulator can represent this value without overflow.

Kiểm thử này xác nhận rằng bộ tích lũy có thể biểu diễn giá trị này mà không bị tràn.

---

## 8. Test Case 7 — Invalid Samples

## Kiểm thử 7 — Mẫu không hợp lệ

Insert cycles where:

Chèn các chu kỳ trong đó:

```text
uio_in[0] = 0
```

The filter must not accept those samples as new window entries.

Bộ lọc không được tiếp nhận các mẫu này như những mẫu mới của cửa sổ.

The reference model also ignores invalid samples.

Mô hình tham chiếu cũng bỏ qua các mẫu không hợp lệ.

This verifies that invalid cycles do not advance the sample window or corrupt the running sum.

Kiểm thử này xác nhận rằng các chu kỳ không hợp lệ không làm dịch chuyển cửa sổ và không làm sai lệch tổng tích lũy.

---

## 9. Test Case 8 — Reset During Operation

## Kiểm thử 8 — Reset giữa quá trình hoạt động

The filter is allowed to process valid samples before reset is asserted.

Bộ lọc được cho phép xử lý một số mẫu hợp lệ trước khi reset được kích hoạt.

After reset:

Sau reset:

```text
sample_count = 0
accumulator  = 0
out_data     = 0
out_valid    = 0
```

The test then applies a new sequence of valid samples and verifies that the filter starts a new eight-sample window.

Sau đó, testbench đưa vào một chuỗi mẫu hợp lệ mới và kiểm tra rằng bộ lọc bắt đầu lại một cửa sổ tám mẫu mới.

This verifies that reset correctly clears the previous operating state.

Kiểm thử này xác nhận rằng reset xóa đúng trạng thái hoạt động trước đó.

---

## 10. Reference Model — Mô hình tham chiếu

The testbench maintains a software/reference window containing the most recent valid samples.

Testbench duy trì một cửa sổ tham chiếu chứa các mẫu hợp lệ gần nhất.

For a full eight-sample window:

Với một cửa sổ đủ tám mẫu:

```text
expected_sum =
    sample[0] +
    sample[1] +
    ...
    sample[7]

expected_average = expected_sum >> 3
```

The RTL output is compared against the reference value.

Kết quả RTL được so sánh với giá trị từ mô hình tham chiếu.

---

## 11. Timing of Output Validation

## Thời điểm kiểm tra đầu ra

The testbench checks the output only when the output valid signal indicates that the result is valid.

Testbench chỉ kiểm tra giá trị đầu ra khi tín hiệu output valid cho biết kết quả là hợp lệ.

This avoids treating the output value during invalid cycles as a valid moving-average result.

Điều này tránh việc xem giá trị trên output trong các chu kỳ không hợp lệ là một kết quả trung bình trượt hợp lệ.

---

## 12. Pass Criteria — Tiêu chí đạt

A test passes when:

Một test được xem là đạt khi:

1. All expected output values match.

   Tất cả giá trị đầu ra thực tế khớp với giá trị mong đợi.

2. Output valid is asserted at the expected time.

   Tín hiệu output valid được xác nhận đúng thời điểm.

3. Invalid input samples do not incorrectly modify the filter state.

   Các mẫu đầu vào không hợp lệ không làm thay đổi sai trạng thái bộ lọc.

4. No accumulator overflow occurs.

   Không xảy ra tràn bộ tích lũy.

5. Reset correctly clears the previous operating state.

   Reset xóa đúng trạng thái hoạt động trước đó.

6. All planned test cases complete successfully.

   Tất cả các test case đã lập kế hoạch đều hoàn thành thành công.
