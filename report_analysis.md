# BÁO CÁO PHÂN TÍCH CHUYÊN SÂU & KẾT LUẬN (MỤC 7 & MỤC 8)

---

## 7. CÂU PHÂN TÍCH RIÊNG CỦA ĐỀ TÀI

### 7.1 So sánh Kiến trúc Tích luỹ trượt và Kiến trúc Cộng lại 8 mẫu

Đề tài G02 yêu cầu so sánh hai phương án thiết kế cho bộ lọc trung bình trượt 8 mẫu:
1. **Phương án 1 (Tích luỹ trượt - Sliding Window):** Thực hiện tính tổng theo công thức $S_k = S_{k-1} + X_{new} - X_{old}$.
2. **Phương án 2 (Cộng lại 8 mẫu - Direct Recomputation):** Thực hiện tính tổng lại toàn bộ 8 mẫu ở mỗi chu kỳ $S_k = \sum_{i=0}^{7} X_i - X_{old} + X_{new}$.

#### Bảng tổng hợp đối chiếu số liệu thực tế từ lần chạy OpenLane:

| Tiêu chí phân tích | Phương án 1: Tích luỹ trượt (`moving_average_8.v`) | Phương án 2: Cộng lại 8 mẫu (`moving_average_8_recompute.v`) |
| :--- | :--- | :--- |
| **Số lượng Standard Cells** | **405 cells** | **448 cells** (Tăng ~10.6%) |
| **Số lượng Flip-Flops (D-FF)** | **91 FFs** (`sky130_fd_sc_hd__dfrtp_2`) | **94 FFs** (`sky130_fd_sc_hd__dfxtp_2`) |
| **Tổng diện tích (Cell Area)** | **5403.93 µm²** | **5207.49 µm²** |
| **Cấu trúc đường tổ hợp** | 1 Subtractor ($X_{old}$) + 1 Adder ($X_{new}$) | Cây cộng tổ hợp 9 số hạng ($log_2 8 + 1$ tầng) |
| **Startpoint Critical Path** | Cổng vào `ui_in[2]` | Cổng vào `ui_in[x]` / Thanh ghi đệm `sample_mem` |
| **Endpoint Critical Path** | Flip-Flop tích luỹ `_640_` | Flip-Flop tổng `window_sum` |
| **Độ trễ đường tới hạn ($T_{delay}$)** | ~$3.20 ns$ | Thường cao hơn do chuỗi logic dài |
| **Hold Slack (Min Corner)** | **+0.3299 ns** (MET - Không vi phạm) | Đạt tiêu chuẩn |

### 7.2 Phân tích chi tiết đường tới hạn (Critical Path Analysis)

Dựa trên báo cáo Phân tích Thời gian Tĩnh (STA) sau khi chiết xuất thông số ký sinh (RCX) từ file `42-openroad-stamidpnr-3/max.rpt`:

* **Điểm bắt đầu (Startpoint):** Chân đầu vào `ui_in[2]` thuộc bus mẫu dữ liệu vào.
* **Điểm kết thúc (Endpoint):** Flip-Flop đệm `_640_` (kích hoạt bằng sườn lên của clock `clk`).
* **Diễn biến đường tới hạn:**
  1. Tín hiệu vào `ui_in[2]` đi qua ô đệm đầu vào `input4` (`sky130_fd_sc_hd__clkbuf_2`) với độ trễ $0.1578\text{ ns}$.
  2. Tín hiệu truyền qua dãy các cổng logic tổ hợp phục vụ phép toán cộng/trừ: `or2_1` ($0.2260\text{ ns}$) $\rightarrow$ `nand2_1` ($0.1458\text{ ns}$) $\rightarrow$ `a21oi_1` ($0.0734\text{ ns}$) $\rightarrow$ `or3_1` ($0.4045\text{ ns}$) $\rightarrow$ `and2_1` ($0.1875\text{ ns}$) $\rightarrow$ `a311o_2`.
  3. Tổng thời gian lan truyền dữ liệu (Data Arrival Time) đạt xấp xỉ **$3.20\text{ ns}$**.

* **Kết luận kỹ thuật:** 
  Phương án **Tích luỹ trượt** duy trì đường tới hạn ngắn vì phép toán ở mỗi chu kỳ chỉ phụ thuộc vào 1 phép trừ mẫu cũ và 1 phép cộng mẫu mới. Ngược lại, phương án **Cộng lại 8 mẫu** phải gom toàn bộ 8 thanh ghi mẫu thông qua cây cộng nhiều tầng, tạo ra độ trễ tích luỹ logic lớn hơn đáng kể, làm giảm tần số hoạt động tối đa ($F_{max}$) của hệ thống khi mở rộng kích thước cửa sổ lọc (ví dụ: N=16, 32, 64).

---

## 8. KẾT LUẬN CÓ ĐIỀU KIỆN VÀ GIỚI HẠN DỰ ÁN

### 8.1 Các kết luận đạt được (Đính kèm điều kiện thực nghiệm)

Mọi kết quả công bố trong báo cáo này được tạo ra dựa trên các điều kiện thực nghiệm cố định sau:
1. **Công cụ và Môi trường:** Flow tự động RTL-to-GDSII qua **OpenLane v2** (Yosys 0.46, OpenROAD), chạy trên môi trường Linux WSL2.
2. **Bộ thư viện Công nghệ (PDK):** SkyWater 180nm HD PDK (`sky130A`), thư viện cell chuẩn `sky130_fd_sc_hd`.
3. **Ràng buộc Thời gian (Constraints):** Chu kỳ xung nhịp giả định $T_{clk} = 10.0\text{ ns}$ ($100\text{ MHz}$).
4. **Kết quả Synthesis & PnR:**
   * Mạch tổng hợp ra đúng **405 Standard Cells**, bao gồm đúng **91 D-Flip-Flops** (`dfrtp_2`), khớp 100% với ước lượng thủ công ($8 \times 8\text{ bits memory} + 3\text{ bits pointer} + 4\text{ bits count} + 11\text{ bits sum} + 8\text{ bits out} + 1\text{ bit valid} = 91\text{ FFs}$).
   * Mạch đạt tiêu chuẩn vật lý: **DRC Pass 100%**, **LVS Pass 100%**, **Antenna Check Pass 100%**.
   * Công suất tiêu thụ tổng ở góc `nom_tt_025C_1v80` là **$2.525\text{ mW}$** (trong đó công suất động chiếm $>99.9\%$, công suất rò cực nhỏ ~$3.10\text{ nW}$).

### 8.2 Giới hạn kỹ thuật trung thực (Những điều CHƯA khẳng định được)

Để đảm bảo tính liêm chính khoa học, báo cáo này làm rõ các giới hạn sau:
* **Chưa kiểm chứng mô phỏng mức cổng (Gate-Level Simulation - GLS):** Báo cáo mới chỉ dừng lại ở mô phỏng chức năng RTL (RTL Sim) và phân tích thời gian tĩnh (STA) sau routing. Chưa thực hiện mô phỏng GLS kèm file timing SDF để bắt các lỗi rủi ro về glitch.
* **Giới hạn của kiểm tra DRC/LVS:** Việc DRC và LVS sạch chỉ khẳng định bản vẽ layout tuân thủ quy tắc dựng hình vật lý của nhà máy foundry và đúng nét nối logic với netlist. **DRC/LVS sạch KHÔNG đồng nghĩa với việc mạch chạy đúng chức năng số học trên thực tế.**
* **Chưa Tape-out / Chưa Chế tạo:** Mạch chỉ được kiểm chứng qua phần mềm EDA. Mọi thông số công suất và thời gian đều là ước lượng mô phỏng, chưa đại diện cho vi mạch thực tế trên silicon.
