## THÔNG TIN CƠ BẢN
LANG_CODE="vi"
LANGUAGE_NAME="Tiếng Việt"
LANGUAGE_NAME_EN="Vietnamese"

# MÃ VĂN BẢN (001000–001999) – CÁC THÀNH PHẦN GIAO DIỆN NGƯỜI DÙNG
TXT_001000="Tiếp tục"
TXT_001001="OK"
TXT_001002="Hủy"
TXT_001003="Thoát"
TXT_001101="Có"
TXT_001102="Không"
TXT_001103="Quay lại"
TXT_001104="Tiếp theo"

# MÃ THÔNG BÁO (002000–002999) – THÔNG ĐIỆP NGƯỜI DÙNG
MSG_002000="Thao tác đã hoàn tất"
MSG_002100="Thành công"
MSG_002101="Thao tác hoàn tất thành công"
MSG_002200="Đang xử lý..."
MSG_002300="Cảnh báo"

# MÃ LOẠI (003000–003999) – DANH MỤC
TYPE_003000="Chung"
TYPE_003100="Cấu hình"
TYPE_003200="Thư mục"
TYPE_003300="Tệp"
TYPE_003400="Mạng"
TYPE_003500="Hệ thống"

# MÃ LỖI (004000–004999) – THÔNG BÁO LỖI
ERR_004000="Đã xảy ra lỗi"
ERR_004100="Lỗi cấu hình"
ERR_004200="Lỗi thư mục"
ERR_004300="Lỗi tệp"
ERR_004400="Lỗi mạng"
ERR_004500="Lỗi hệ thống"

# MÃ GHI NHẬT KÝ (005000–005999) – TỆP NHẬT KÝ
LOG_005000="Sự kiện đã được ghi"
LOG_005100="Ứng dụng đã khởi động"
LOG_005101="Ứng dụng đã thoát"
LOG_005200="Đã tải cấu hình"
LOG_005201="Đã lưu cấu hình"
LOG_005300="Tệp đã được xử lý"
LOG_005301="Tệp đã được tạo"
LOG_005302="Tệp đã bị xóa"

# MÃ CẤU HÌNH (006000–006999) – GIAO DIỆN CẤU HÌNH
CFG_006000="Cấu hình"
CFG_006100="Thiết lập"
CFG_006101="Thiết lập chung"
CFG_006102="Thiết lập mạng"
CFG_006103="Thiết lập bảo mật"
CFG_006200="Trình hướng dẫn cài đặt"
CFG_006201="Chào mừng đến với trình cài đặt"
CFG_006202="Cài đặt hoàn tất"

# MÃ TRỢ GIÚP (007000–007999) – ĐẦU RA --help
HELP_007000="Trợ giúp"
HELP_007100="Cách sử dụng"
HELP_007101="Cú pháp"
HELP_007102="Tham số"
HELP_007103="Tùy chọn"
HELP_007200="Ví dụ"
HELP_007300="Mô tả"

# MÃ TIẾN TRÌNH (008000–008999) – TRẠNG THÁI TIẾN TRÌNH
PROG_008000="Tiến trình"
PROG_008100="Đang cài đặt..."
PROG_008101="Đang tải xuống..."
PROG_008102="Đang xử lý..."
PROG_008104="Đang khởi tạo..."
PROG_008200="Hoàn tất"
PROG_008201="Cài đặt hoàn tất"
PROG_008202="Tải xuống hoàn tất"

# MÃ NHẬP LIỆU (009000–009999) – NHẮC NHẬP LIỆU NGƯỜI DÙNG
INPUT_009000="Yêu cầu nhập liệu"
INPUT_009100="Nhập giá trị"
INPUT_009101="Nhập đường dẫn"
INPUT_009102="Nhập tên"
INPUT_009200="Xác nhận"
INPUT_009201="Bạn có chắc không?"
INPUT_009202="Xác nhận xóa"

# MÃ MENU (010000–010999) – HỆ THỐNG MENU (hex cho nhóm thứ 10)
MENU_010000="Trình đơn"
MENU_010100="Trình đơn chính"
MENU_010101="Trình đơn cài đặt"
MENU_010102="Trình đơn công cụ"
MENU_010200="Chọn tùy chọn"
MENU_010201="Điều hướng"

CODE_META_MAP=(
  # Văn bản giao diện người dùng (010000–019999)
  [001]="TXT:Văn bản không xác định"
  [002]="MSG:Thông báo không xác định"
  [003]="TYPE:Loại không xác định"

  # Lỗi, ghi nhật ký, cấu hình (040000–069999)
  [004]="ERR:Lỗi không xác định"
  [005]="LOG:Sự kiện nhật ký không xác định"
  [006]="CFG:Cấu hình không xác định"

  # Trợ giúp, tiến trình, nhập liệu, menu (070000–100000)
  [007]="HELP:Trợ giúp không xác định"
  [008]="PROG:Tiến trình không xác định"
  [009]="INPUT:Nhập liệu không xác định"
  [010]="MENU:Trình đơn không xác định"
)
