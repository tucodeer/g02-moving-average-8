# G02 — 8-Point Moving Average Filter

RTL implementation of an 8-point moving average filter for digital signal processing.

This project is developed as part of an RTL-to-GDSII digital design workflow, including RTL design, functional verification, synthesis, static timing analysis (STA), physical implementation, and final layout generation using Sky130A.

---

# TÀI LIỆU TIẾNG VIỆT

## 1. Tổng quan

Đây là thiết kế **bộ lọc trung bình trượt 8 điểm (8-point Moving Average Filter)** được thực hiện bằng RTL Verilog.

Mục tiêu của project không chỉ là xây dựng mạch thực hiện đúng chức năng, mà còn thực hiện toàn bộ quy trình thiết kế số:

```text
RTL
 ↓
Functional Verification
 ↓
Synthesis
 ↓
Static Timing Analysis (STA)
 ↓
Floorplan
 ↓
Placement
 ↓
Clock Tree Synthesis (CTS)
 ↓
Routing
 ↓
Post-route STA
 ↓
DRC / LVS
 ↓
GDSII
```

Flow ASIC được thực hiện bằng **OpenLane 2.3.10** với **Sky130A PDK**.

> Lưu ý: Project này chỉ mô phỏng và thực hiện flow RTL-to-GDSII bằng công cụ EDA. Không được hiểu là thiết kế đã được sản xuất hoặc kiểm chứng trên silicon.

---

## 2. Đặc tả thiết kế

| Tín hiệu      | Kích thước | Chức năng                 |
| ------------- | ---------: | ------------------------- |
| `clk`         |      1 bit | Clock                     |
| `rst_n`       |      1 bit | Reset tích cực mức thấp   |
| `ui_in[7:0]`  |      8 bit | Mẫu dữ liệu đầu vào       |
| `uio_in[0]`   |      1 bit | Input valid               |
| `uo_out[7:0]` |      8 bit | Giá trị trung bình đầu ra |
| `uio_out[0]`  |      1 bit | Output valid              |

### Thông số chính

* Kích thước cửa sổ: **8 mẫu**
* Input sample: **8 bit**
* Output average: **8 bit**
* Tổng tối đa của 8 mẫu:

```text
8 × 255 = 2040
```

Do đó accumulator cần ít nhất **11 bit**.

* Chia cho 8 được thực hiện bằng dịch phải 3 bit:

```text
average = sum >> 3
```

* Chỉ các chu kỳ có `valid = 1` mới cập nhật trạng thái.
* 7 mẫu đầu tiên chưa tạo ra output hợp lệ.
* Từ mẫu thứ 8 trở đi, output hợp lệ.
* Khi reset, bộ nhớ mẫu, accumulator, bộ đếm, output và output-valid được xóa.

---

## 3. Kiến trúc

Thiết kế sử dụng phương pháp **Sliding Accumulation (tích lũy trượt)**.

Thay vì mỗi chu kỳ cộng lại toàn bộ 8 mẫu, mạch duy trì tổng của cửa sổ hiện tại.

Khi có mẫu mới:

```text
new_sum = old_sum - oldest_sample + new_sample
```

Sau đó:

```text
average = new_sum >> 3
```

### Ví dụ

Giả sử cửa sổ hiện tại là:

```text
10 20 30 40 50 60 70 80
```

Tổng:

```text
360
```

Nếu mẫu mới là `90`, mẫu cũ nhất `10` bị loại khỏi cửa sổ:

```text
new_sum = 360 - 10 + 90
        = 440
```

Cửa sổ mới:

```text
20 30 40 50 60 70 80 90
```

Giá trị trung bình:

```text
440 / 8 = 55
```

### Circular Buffer

Các mẫu được lưu trong một **Circular Buffer (bộ đệm vòng)** gồm 8 phần tử.

Write pointer lần lượt chạy:

```text
0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 0 → ...
```

Khi pointer quay lại vị trí cũ, mẫu cũ nhất tại vị trí đó được thay thế bằng mẫu mới.

---

## 4. Vì sao sử dụng Sliding Accumulation?

Có hai cách triển khai:

### Cách 1 — Sliding Accumulation

```text
new_sum = old_sum - oldest_sample + new_sample
```

Mỗi lần cập nhật chỉ cần:

* trừ mẫu cũ
* cộng mẫu mới

### Cách 2 — Recompute

Mỗi chu kỳ tính lại:

```text
sample[0] + sample[1] + ... + sample[7]
```

Cách này cần nhiều phép cộng hơn.

Project thực hiện cả hai kiến trúc để so sánh:

* số lượng cell
* logic tổ hợp
* critical path
* timing
* timing slack

---

## 5. Functional Verification

Testbench được thiết kế theo hướng **self-checking**.

Thay vì chỉ quan sát waveform, testbench tự tính giá trị mong đợi và so sánh với output của DUT.

Các trường hợp kiểm thử gồm:

* Basic window fill
* Sliding window
* Constant sequence
* Step sequence
* Random sequence
* Accumulator overflow
* Invalid input
* Reset giữa quá trình hoạt động

### Invalid input

Khi:

```text
valid = 0
```

mẫu đầu vào phải được bỏ qua.

Điều đó có nghĩa là:

* không cập nhật buffer
* không thay đổi accumulator
* không tăng sample counter
* không tạo output valid

### Reset giữa quá trình hoạt động

Testbench cũng kiểm tra trường hợp reset được kích hoạt khi mạch đang hoạt động.

Sau reset, trạng thái của bộ lọc phải quay về trạng thái ban đầu.

---

## 6. Timing Comparison

Project so sánh hai kiến trúc:

1. Sliding accumulation
2. Recompute toàn bộ tổng 8 mẫu

Các tiêu chí chính:

* Cell count
* Combinational logic
* Flip-flop count
* Critical path
* Timing slack
* Estimated maximum frequency

Kết quả thực nghiệm được lưu trong thư mục:

```text
results/
```

Các kết quả trong thư mục này được tạo từ chính flow synthesis/STA/OpenLane của project.

---

## 7. RTL-to-GDSII Flow

Project sử dụng:

```text
OpenLane 2.3.10
Sky130A
sky130_fd_sc_hd
```

Các bước chính:

```text
RTL
 ↓
Synthesis
 ↓
Floorplan
 ↓
Power Planning
 ↓
Placement
 ↓
CTS
 ↓
Routing
 ↓
Parasitic Extraction
 ↓
Post-route STA
 ↓
DRC / LVS / Antenna Checks
 ↓
GDSII
```

### Ý nghĩa ngắn gọn

**Synthesis**

Chuyển RTL thành mạng các standard cell.

**Floorplan**

Xác định kích thước và bố trí tổng thể của vùng thiết kế.

**Placement**

Đặt các standard cell vào vị trí cụ thể.

**CTS — Clock Tree Synthesis**

Xây dựng mạng clock để phân phối clock tới các phần tử tuần tự.

**Routing**

Tạo các đường kim loại kết nối giữa các cell.

**Parasitic Extraction**

Ước lượng các ký sinh của dây sau routing.

**Post-route STA**

Kiểm tra timing sau khi đã có thông tin routing và parasitic.

**DRC**

Kiểm tra thiết kế có vi phạm các quy tắc hình học của công nghệ hay không.

**LVS**

Kiểm tra layout có tương ứng với netlist hay không.

**GDSII**

Tệp dữ liệu layout cuối cùng được tạo ra từ flow.

---

## 8. Cấu trúc thư mục

```text
rtl/        RTL source code
tb/         Testbench
sim/        Simulation scripts and waveforms
synth/      Synthesis files and reports
sta/        Static Timing Analysis
openlane/   ASIC implementation configuration
results/    Important experimental results
docs/       Documentation and report
```

### Giải thích

| Thư mục     | Nội dung                          |
| ----------- | --------------------------------- |
| `rtl/`      | Mã Verilog của thiết kế           |
| `tb/`       | Testbench kiểm thử                |
| `sim/`      | File và script phục vụ simulation |
| `synth/`    | Kết quả synthesis                 |
| `sta/`      | Static Timing Analysis            |
| `openlane/` | Cấu hình OpenLane                 |
| `results/`  | Các kết quả quan trọng            |
| `docs/`     | Tài liệu và báo cáo               |

---

## 9. Reproducibility

Project được thiết kế để có thể chạy lại flow bằng các công cụ và cấu hình được ghi trong repository.

Các thông tin quan trọng gồm:

```text
RTL source
Testbench
STA constraints
OpenLane configuration
PDK
Tool version
Git commit history
GitHub Actions CI
```

GitHub Actions được sử dụng để tự động kiểm tra:

1. RTL simulation
2. RTL-to-GDSII flow

---

## 10. Mục tiêu của project

Project nhằm thực hành toàn bộ quá trình từ:

```text
Ý tưởng thuật toán
      ↓
Kiến trúc phần cứng
      ↓
RTL
      ↓
Verification
      ↓
Synthesis
      ↓
STA
      ↓
Physical Design
      ↓
Layout
```

Qua đó có thể quan sát mối quan hệ giữa:

```text
Kiến trúc RTL
     ↓
Logic được tổng hợp
     ↓
Area
     ↓
Timing
     ↓
Physical implementation
```

Đặc biệt, project sử dụng phép so sánh **Sliding Accumulation vs Recompute** để đánh giá ảnh hưởng của lựa chọn kiến trúc RTL tới area và timing.

---

# English Documentation

## Specification

* Input sample: `ui_in[7:0]`
* Input valid: `uio_in[0]`
* Output average: `uo_out[7:0]`
* Output valid: `uio_out[0]`
* Window size: 8 samples
* Division by 8: right shift by 3 bits
* The design must use sliding accumulation instead of recomputing the sum of all eight samples every cycle.

## Architecture

The main implementation uses sliding accumulation:

```text
new_sum = old_sum - old_sample + new_sample
average = sum >> 3
```

A circular buffer stores the eight samples.

## Verification

The self-checking testbench covers:

* Basic window fill
* Sliding window
* Constant sequence
* Step sequence
* Random sequence
* Accumulator overflow
* Invalid input
* Reset during operation

## Timing Comparison

Two architectures are compared:

1. Sliding accumulation
2. Recomputing the sum of eight samples

The comparison focuses on:

* Cell count
* Logic depth
* Critical path
* Timing slack
* Estimated maximum frequency

## Project Structure

```text
rtl/        RTL source code
tb/         Testbench
sim/        Simulation scripts and waveforms
synth/      Synthesis files and reports
sta/        Static timing analysis
openlane/   ASIC implementation flow
results/    Important results
docs/       Documentation and report
```
