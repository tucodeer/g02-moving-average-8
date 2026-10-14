# BÁO CÁO KẾT QUẢ VÀ BÀN LUẬN

**Đề tài:** Thiết kế Bộ lọc trung bình trượt 8 mẫu (Moving Average Filter N=8) — Mã đề G02  
**Môn học:** Nhập môn Thiết kế Vi mạch Tích hợp (EEE703128)  
**Giảng viên hướng dẫn:** Đinh Văn Nam  
**Sinh viên thực hiện:** [Họ và tên] | **MSSV:** [Mã sinh viên] | **Lớp:** [Tên lớp]

---

## 1. ĐẶC TẢ VÀ SƠ ĐỒ KHỐI

### 1.1 Yêu cầu chức năng

Bộ lọc trung bình trượt 8 mẫu tiếp nhận luồng dữ liệu đầu vào 8-bit (`ui_in`) theo từng chu kỳ xung nhịp và thực hiện làm mượt tín hiệu bằng cách tính trung bình cộng của cửa sổ 8 mẫu gần nhất. Kết quả thu được được thực hiện phép chia cho 8 bằng cách dịch phải 3 bit (`>> 3`) trước khi xuất ra cổng `uo_out`.

### 1.2 Bảng tín hiệu giao diện và xử lý ánh xạ chân

Theo đặc tả giao diện khung Tiny Tapeout, tổng số chân I/O là 24 chân (8 chân vào `ui_in`, 8 chân ra `uo_out`, và 8 chân bidir `uio`).

* **Khắc phục lỗi đề bài:** Đề bài ban đầu gán trùng chân `uio[0]` cho cả đầu vào và đầu ra. Thiết kế đã sửa đổi bằng cách phân tách rõ vai trò tín hiệu trên giao diện:
  * `uio_in[0]`: Tín hiệu `sample_valid` (Đầu vào, tích cực mức cao) — Báo mẫu dữ liệu `ui_in` ở chu kỳ hiện tại là hợp lệ.
  * `uio_out[0]`: Tín hiệu `out_valid` (Đầu ra, tích cực mức cao) — Báo kết quả lọc `uo_out` đã đủ 8 mẫu và hợp lệ.
  * `uio_out[7:1]`: Gán cố định `7'b0`.

| Tên tín hiệu | Chiều | Độ rộng (bit) | Mức tích cực | Ý nghĩa chức năng |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | 1 | Sườn lên | Xung nhịp hệ thống |
| `rst_n` | Input | 1 | Mức thấp (`0`) | Reset bất đồng bộ hệ thống |
| `ui_in[7:0]` | Input | 8 | — | Mẫu dữ liệu đầu vào ($X_{new}$) |
| `uio_in[0]` | Input | 1 | Mức cao (`1`) | Tín hiệu báo mẫu đầu vào hợp lệ (`sample_valid`) |
| `uo_out[7:0]` | Output | 8 | — | Giá trị trung bình trượt đầu ra ($Y$) |
| `uio_out[0]` | Output | 1 | Mức cao (`1`) | Tín hiệu báo kết quả đầu ra hợp lệ (`out_valid`) |
| `uio_out[7:1]` | Output | 7 | — | Chân dự phòng, gán bằng `0` |

### 1.3 Xử lý các trường hợp biên

* **Trạng thái Reset:** Khi `rst_n = 0`, toàn bộ 8 ô nhớ trong mảng thanh ghi `sample_mem[0:7]`, con trỏ ghi `wr_ptr`, bộ đếm mẫu `sample_count`, và thanh ghi tích luỹ `sum` đều được xóa về `0`.
* **Khởi tạo cửa sổ (Window Startup):** Trong 7 chu kỳ dữ liệu hợp lệ đầu tiên (`sample_count < 7`), cửa sổ lọc chưa đủ 8 mẫu, tín hiệu `out_valid` (`uio_out[0]`) giữ ở mức `0`. Đến mẫu hợp lệ thứ 8 (`sample_count == 7`), `out_valid` bắt đầu lên `1` và giữ nguyên mức `1` cho các chu kỳ tiếp theo.
* **Biên số học và Chống tràn:** Với 8 mẫu 8-bit, giá trị tổng cực đại là $255 \times 8 = 2040$. Bộ tích luỹ `sum` được thiết kế có độ rộng **11-bit** (biểu diễn tối đa $2^{11}-1 = 2047$), do đó khẳng định **không bao giờ bị tràn số** ngay cả khi nạp liên tục các mẫu có giá trị max `8'hFF`.

---

## 2. RTL VÀ KIỂM CHỨNG CHỨC NĂNG

### 2.1 Kiến trúc RTL tự viết (Sliding Accumulation)

Mã nguồn Verilog (`rtl/moving_average_8.v`) áp dụng thuật toán tích luỹ trượt. Thay vì cộng lại cả 8 mẫu mỗi chu kỳ, mạch duy trì thanh ghi tích luỹ `sum` và chỉ thực hiện 1 phép trừ mẫu cũ nhất cùng 1 phép cộng mẫu mới nhất:

$$\text{sum}_{new} = \text{sum}_{old} - \text{sample\_mem}[\text{wr\_ptr}] + \text{ui\_in}$$

```verilog
// Trich doan logic cap nhat tich luy trượt trong RTL
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr       <= 3'd0;
        sample_count <= 4'd0;
        sum          <= 11'd0;
        out_data     <= 8'd0;
        out_valid    <= 1'b0;
        // Reset mảng đệm sample_mem...
    end else if (uio_in[0]) begin
        sample_mem[wr_ptr] <= ui_in;
        if (sample_count < 4'd8)
            sample_count <= sample_count + 1'b1;

        if (wr_ptr == 3'd7) wr_ptr <= 3'd0;
        else wr_ptr <= wr_ptr + 1'b1;

        if (sample_count < 4'd7) begin
            sum <= sum + ui_in;
        end else if (sample_count == 4'd7) begin
            sum <= sum + ui_in;
            out_data <= (sum + ui_in) >> 3;
            out_valid <= 1'b1;
        end else begin
            sum <= (sum - sample_mem[wr_ptr]) + ui_in;
            out_data <= ((sum - sample_mem[wr_ptr]) + ui_in) >> 3;
        end
    end
end
```

### 2.2 Testbench và Kiểm chứng ca mô phỏng

File Testbench (`tb/moving_average_8_tb.v`) bao phủ toàn bộ các ca kiểm thử của đề cộng thêm 2 ca biên tự xây dựng:

* **Ca 1 (Chuỗi hằng):** Nạp liên tục chuỗi mẫu $10$, sau 8 mẫu đầu ra ổn định ở giá trị $10$.
* **Ca 2 (Phản ứng bước nhảy - Step response):** Tín hiệu vào nhảy đột ngột từ $0 \rightarrow 80$, đầu ra tăng tiến mượt qua các giá trị $10, 20, 30, \dots, 80$.
* **Ca 3 (Ca biên bổ sung 1 - Tràn bộ tích luỹ):** Nạp liên tục 8 mẫu max $255$ (`8'hFF`). Tổng đạt $2040$, đầu ra đạt $255$, chứng minh bộ tích luỹ 11-bit không bị tràn.
* **Ca 4 (Ca biên bổ sung 2 - Reset đột ngột giữa chừng):** Kích hoạt `rst_n = 0` tại chu kỳ nhận mẫu thứ 4. Hệ thống ngay lập tức xóa bộ đếm và cờ `out_valid` về 0, khẳng định tính khôi phục an toàn.

**Bảng đối chiếu kết quả Mong đợi vs Thu được:**

| Ca kiểm thử | Giá trị đầu vào (`ui_in`) | Kết quả tính tay mong đợi | Kết quả mô phỏng (`uo_out`) | Đánh giá |
| :--- | :--- | :--- | :--- | :---: |
| Chuỗi hằng | 8 mẫu liên tục $= 10$ | $80 / 8 = 10$ | $10$ (`out_valid = 1`) | PASS ✅ |
| Bước nhảy | Nhảy từ $0 \rightarrow 80$ | Tăng dần $10, 20, \dots, 80$ | $10, 20, 30, \dots, 80$ | PASS ✅ |
| Tràn tích luỹ | 8 mẫu max $= 255$ (`8'hFF`) | Total $2040 \rightarrow Y = 255$ | $255$ (`out_valid = 1`) | PASS ✅ |
| Reset giữa chừng | `rst_n = 0` tại mẫu thứ 4 | `sum=0`, `out_valid=0` | `sum=0`, `out_valid=0` | PASS ✅ |

---

## 3. BÁO CÁO TỔNG HỢP (SYNTHESIS)

### 3.1 Đối chiếu Ước lượng thủ công vs Kết quả Tổng hợp Yosys

**Tính toán thủ công số Flip-Flop (FF):**

* Mảng đệm 8 mẫu 8-bit (`sample_mem`): $8 \times 8 = 64$ FFs.
* Con trỏ ghi (`wr_ptr`): 3 FFs.
* Bộ đếm mẫu (`sample_count`): 4 FFs.
* Thanh ghi tích luỹ (`sum`): 11 FFs.
* Thanh ghi dữ liệu ra (`out_data`): 8 FFs.
* Thanh ghi báo hợp lệ (`out_valid`): 1 FF.

**Tổng ước lượng thủ công:** $64 + 3 + 4 + 11 + 8 + 1 = \mathbf{91\ \text{Flip-Flops}}$.

**Đối chiếu kết quả tổng hợp thực tế (Yosys JSON report):**

* Tổng số Standard Cells thu được: **389 cells** (với thiết kế `moving_average_8.v`).
* Số lượng ô Flip-Flop: Đúng **91 cells** `sky130_fd_sc_hd__dfrtp_2` (D-Flip-Flop có chân Reset tích cực mức thấp).
* **Khớp 100%** giữa ước lượng thủ công và kết quả tổng hợp thực tế.
* Tổng diện tích cell sau tổng hợp (Cell Area): $5403.93\ \mu\text{m}^2$.

---

## 4. BÁO CÁO THỜI GIAN (STA)

Phân tích thời gian tĩnh được thực hiện bằng OpenSTA trên netlist sau khi định tuyến (Post-route RCX) với góc phân tích `nom_tt_025C_1v80`.

### 4.1 Số liệu Slack và Tần số tối đa

* **Setup Slack (Worst Max Corner):** Đạt Slack dương ($+4.828\text{ ns}$ trên chu kỳ xung nhịp ràng buộc $T_{clk} = 10.0\text{ ns}$), khẳng định mạch không vi phạm thời gian thiết lập.
* **Hold Slack (Worst Min Corner):** $+0.3299\text{ ns}$ (slack MET), khẳng định mạch không bị vi phạm thời gian giữ và không xảy ra hiện tượng đua tín hiệu (race condition).
* **Thời gian trễ đường tới hạn ($T_{delay}$):** Độ trễ lớn nhất qua chuỗi logic tổ hợp là $5.172\text{ ns}$.
* **Tần số hoạt động tối đa ($F_{max}$):**

$$T_{min} \approx 5.341\text{ ns} \implies F_{max} = \frac{1}{T_{min}} \approx \mathbf{187.2\text{ MHz}}$$

### 4.2 Truy vết Đường tới hạn (Critical Path)

* **Startpoint:** Chân đầu vào `ui_in[2]` (Input port clocked by clk).
* **Endpoint:** Flip-Flop đệm tích luỹ `_640_` (Rising edge-triggered flip-flop).
* **Mô tả đường truyền:** Tín hiệu từ `ui_in[2]` đi qua ô đệm cổng vào `input4` (`sky130_fd_sc_hd__clkbuf_2`) $\rightarrow$ truyền qua chuỗi cổng logic tổ hợp phục vụ phép cộng/trừ: `or2_1` $\rightarrow$ `nand2_1` $\rightarrow$ `a21oi_1` $\rightarrow$ `or3_1` $\rightarrow$ `and2_1` $\rightarrow$ `a311o_2` $\rightarrow$ đi tới chân dữ liệu $D$ của Flip-Flop `_640_`.

---

## 5. BÁO CÁO CÔNG SUẤT VÀ KIỂM TRA VẬT LÝ

### 5.1 Báo cáo công suất tiêu thụ (Corner `nom_tt_025C_1v80`)

* **Internal Power:** $1.6219\text{ mW}$ ($64.2\%$)
* **Switching Power:** $0.9035\text{ mW}$ ($35.8\%$)
* **Leakage Power:** $3.1060\text{ nW}$ ($< 0.01\%$)
* **Tổng công suất tiêu thụ (Total Power):** $2.5254\text{ mW}$

**Nhận xét:** Công suất động (Dynamic Power = Internal + Switching) chi phối $> 99.9\%$ tổng công suất tiêu thụ do tần số chuyển mạch liên tục của bộ cộng và mảng thanh ghi. Công suất rò (Leakage Power) ở công nghệ Sky130 180nm ở nhiệt độ $25^\circ\text{C}$ là không đáng kể.

### 5.2 Kết quả kiểm tra vật lý (Physical Verification)

* **DRC (Design Rule Check):** Passed ✅ (0 violation)
* **LVS (Layout Versus Schematic):** Passed ✅ (Netlist và Layout tương đương 100%)
* **Antenna Check:** Passed ✅ (0 violation)

> **Giới hạn nhận thức:** Kết quả DRC/LVS sạch chỉ khẳng định bản vẽ layout tuân thủ đầy đủ quy tắc hình học của nhà máy chế tạo (foundry) và nét nối vật lý đúng với netlist. DRC/LVS sạch **KHÔNG** đồng nghĩa với việc mạch chạy đúng chức năng số học hay đạt đáp ứng thời gian trên thực tế.

---

## 6. QUAN SÁT LAYOUT VÀ LIÊN HỆ QUY TRÌNH CHẾ TẠO

### 6.1 Bố trí Layout thực tế (`docs/images/g02_layout_full.png`)

* **Khu vực Core & Cell Density:** Vùng trung tâm chứa các Standard Cells được xếp thành từng hàng chuẩn. Xung quanh viền được đặt các ô Tap/Endcap cell để chống hiện tượng Latch-up và đảm bảo phân bố nguồn.
* **Định hướng đi dây kim loại (Metal Layers):**
  * Lớp `met1` và `met2` (hướng đi ngang/dọc bên dưới): Chủ yếu dùng nối nội bộ giữa các transistor bên trong Standard Cell.
  * Lớp `met3` và `met4` (hướng đi dây phía trên): Được dùng cho đường truyền dữ liệu toàn cục, tín hiệu Reset và mạng phân phối xung nhịp (Clock Tree).

### 6.2 Liên hệ khái niệm Quy trình Chế tạo Vi mạch

* **Photolithography (Quang khắc):** Các lớp Metal và Via quan sát được trên layout tương ứng với các mặt nạ quang khắc dùng để định hình hoa văn mạch trên vi phiến silicon.
* **CVD / Metallization (Lắng đọng kim loại):** Việc hình thành các đường dây dẫn nhôm/đồng nối giữa các ô logic tương ứng với bước lắng đọng màng mỏng kim loại trong phòng sạch.
* **Etching (Ăn mòn):** Các khoảng trống giữa các đường dây nối thể hiện kết quả của bước ăn mòn hóa học/plasma để loại bỏ phần kim loại dư thừa.

---

## 7. CÂU PHÂN TÍCH RIÊNG CỦA ĐỀ TÀI (TRỌNG TÂM G02)

### So sánh Đường tới hạn: Tích luỹ trượt (Sliding) vs Tính lại 8 mẫu (Recompute)

Đề tài thực hiện chạy flow RTL-to-GDSII song song trên cả hai phương án kiến trúc để trích xuất số liệu đối chiếu:

| Chỉ số so sánh | Phương án 1: Tích luỹ trượt (`moving_average_8.v`) | Phương án 2: Tính lại 8 mẫu (`moving_average_8_recompute.v`) | Chênh lệch / Bản chất kỹ thuật |
| :--- | :---: | :---: | :--- |
| Số cell Sky130 Mapped | 389 cells | 490 cells | Recompute tốn hơn 101 cells (+25.9%) do cấu trúc cây cộng. |
| Số Flip-Flops (D-FF) | 91 FFs | 80 FFs | Sliding tốn hơn 11 FFs để giữ thanh ghi `sum`. |
| Combinational Cells | 298 cells | 410 cells | Recompute tốn thêm 112 cells tổ hợp cho mạng cộng 8 mẫu. |
| Worst Path Arrival ($T_{delay}$) | 5.172 ns | 6.363 ns | Recompute chậm hơn 1.191 ns do chuỗi cộng kéo dài. |
| Tần số tối đa ($F_{max}$) | ~187.2 MHz | ~154.2 MHz | Sliding nhanh hơn ~33 MHz (+21.4%). |

**Lập luận bản chất kỹ thuật:**

* **Kiến trúc Tích luỹ trượt:** Độ phức tạp tính toán ở mỗi chu kỳ là cố định $O(1)$, chỉ gồm 1 phép trừ ($X_{old}$) và 1 phép cộng ($X_{new}$). Chuỗi logic tổ hợp ngắn giúp giảm độ trễ đường tới hạn ($5.172\text{ ns}$), đảm bảo khả năng mở rộng tốc độ cao.
* **Kiến trúc Tính lại:** Phải gom cả 8 thanh ghi mẫu thông qua cây cộng tổ hợp 9 số hạng ($\log_2 8 + 1$ tầng cộng). Chuỗi logic kéo dài qua nhiều tầng bộ cộng làm tăng đáng kể độ trễ đường tới hạn ($6.363\text{ ns}$), khiến $F_{max}$ giảm xuống chỉ còn $154.2\text{ MHz}$.

---

## 8. KẾT LUẬN CÓ ĐIỀU KIỆN VÀ GIỚI HẠN

### 8.1 Kết luận đạt được (Đính kèm điều kiện tạo ra)

* **Điều kiện thực nghiệm:** Flow tự động RTL-to-GDSII chạy qua OpenLane v2, bộ PDK SkyWater 180nm HD (`sky130A`), ràng buộc chu kỳ xung nhịp $T_{clk} = 10.0\text{ ns}$.
* **Kết quả:** Mạch thiết kế đúng chức năng số học, tổng hợp ra đúng 91 D-FFs (khớp 100% ước lượng), đạt $F_{max} \approx 187.2\text{ MHz}$, tiêu thụ $2.525\text{ mW}$, và đạt DRC/LVS/Antenna Pass 100%.

### 8.2 Giới hạn kỹ thuật trung thực

* Báo cáo dừng lại ở phân tích thời gian tĩnh (STA) và mô phỏng chức năng RTL; chưa thực hiện mô phỏng mức cổng kèm thời gian thực (Gate-Level Simulation with SDF).
* Mọi thông số thời gian và công suất đều là kết quả mô phỏng EDA, không đại diện cho vi mạch thực tế sau chế tạo silicon.

---

## 9. TRÌNH BÀY VÀ TÍNH TÁI LẬP

### 9.1 Thông tin tái lập

* **Repository GitHub:** https://github.com/tucodeer/g02-moving-average-8
* **Công cụ & Môi trường:** OpenLane v2, Yosys 0.46, OpenROAD, SkyWater 180nm HD PDK (`sky130A`), Ubuntu 22.04 LTS trên WSL2.

### 9.2 Lịch sử Commit

Lịch sử commit trên repository thể hiện rõ tiến trình phát triển từng bước của dự án (khai báo RTL $\rightarrow$ Testbench $\rightarrow$ Sửa lỗi gán chân $\rightarrow$ Tổng hợp Synthesis $\rightarrow$ Chạy STA so sánh 2 kiến trúc).
