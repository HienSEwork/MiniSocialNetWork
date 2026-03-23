# Project Working Rules

## Core Rule
- Tiếng Việt là key quan trọng của dự án.
- Mọi agent khi nhận lệnh trong project này phải đọc file `Rule.md` trước khi phân tích, sửa code, hoặc trả lời.

## Language Rules
- Ưu tiên tiếng Việt có dấu cho toàn bộ text hiển thị với người dùng.
- Không tự ý đổi text tiếng Việt có dấu thành text không dấu.
- Không trộn Anh - Việt trong cùng một luồng UI nếu không thật sự cần thiết.
- Với fallback, thông báo lỗi, trạng thái rỗng, label, placeholder:
  - ưu tiên tiếng Việt ngắn, rõ, dễ hiểu
  - tránh câu dài, tránh text kiểu demo/sample

## UI Rules
- Chỉ giữ các thành phần đúng với nhu cầu thật của dự án.
- Không thêm widget, card, panel, shortcut thừa.
- Giao diện phải gọn, rõ, ưu tiên nội dung chính.
- Nếu không có dữ liệu:
  - hiển thị fallback ngắn gọn
  - chữ nhỏ, rõ, không dùng text giả lập dài dòng

## Data Rules
- Ưu tiên dữ liệu thật từ DB/service.
- Chỉ dùng seed data khi cần để test luồng thật của hệ thống.
- Không hiển thị text hardcode kiểu mô phỏng nếu có thể lấy từ DB/query.

## Workflow Rules
- Khi đã có mục trong `Checklist.md` được tick done, không rà lại phần đó nếu user không yêu cầu.
- Khi sửa bug hoặc thêm tính năng mới, ưu tiên phần chưa done trong checklist.
- Trước khi kết luận xong việc:
  - build lại project nếu có sửa code
  - báo rõ phần nào đã sửa
  - báo rõ nếu có phần chưa verify runtime

## Auth/UI Specific Rules
- Login/Register và các màn account phải gọn, ít chữ thừa.
- Feed phải ưu tiên luồng bài đăng, comment inline, không tản sang màn phụ nếu không cần.
- Header, sidebar, feed layout phải nhất quán với design direction đang chọn.
