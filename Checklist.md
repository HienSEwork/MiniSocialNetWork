# Mini Social App Checklist

## Rule of Work
- [ ] Khi user báo một mục đã test xong, đổi checkbox mục đó sang `done`.
- [ ] Khi dò code ở các lượt sau, bỏ qua các mục đã `done` để tập trung vào phần chưa xong.
- [ ] Chỉ rà lại mục đã `done` nếu user yêu cầu rõ hoặc có bug mới liên quan trực tiếp.

## Auth
- [ ] Login layout 2 cột: trái ảnh, phải form
- [ ] Login form height desktop khoảng 400px
- [ ] Login button đủ rộng, hover đẹp
- [ ] Login visual nền kính/pha lê hoặc ảnh phù hợp
- [ ] Login không reload vô hạn
- [ ] Register đồng bộ style với Login
- [ ] Forgot Password đồng bộ style
- [ ] Account pages không còn bố cục thừa

## Routing
- [ ] `/` redirect đúng
- [x] `/feed` là entry social chính
- [ ] `/dashboard` tách layout riêng hoàn toàn
- [ ] `/Account/*` render ổn định, không loop

## Database
- [ ] Auto migration mỗi lần run dự án
- [ ] Auto seed mỗi lần run dự án
- [ ] Seed idempotent, không nhân bản dữ liệu
- [ ] Login seed account dùng được ngay
- [ ] Role/User bootstrap ổn định

## Feed
- [ ] Cột giữa là trọng tâm
- [ ] Composer gọn, ít chữ thừa
- [ ] Post card dùng dữ liệu DB thật
- [ ] Fallback khi không tải được dữ liệu là chữ nhỏ màu đen
- [ ] Reactions/comments hoạt động đúng

## Friends
- [ ] Bỏ text demo/hardcode thừa
- [ ] Dùng dữ liệu DB thật
- [ ] Add friend hoạt động đúng
- [ ] Remove friend hoạt động đúng
- [ ] Empty/fallback state gọn

## Groups
- [ ] Dùng dữ liệu DB thật
- [ ] Create group hoạt động đúng
- [ ] Join/Leave group hoạt động đúng
- [ ] Group posts hoạt động đúng
- [ ] Group chat hoạt động đúng
- [ ] Empty/fallback state gọn

## Chat
- [ ] Layout 2 cột gọn
- [ ] Conversation list dùng dữ liệu DB thật
- [ ] Realtime private chat hoạt động đúng
- [ ] Message bubble style hoàn chỉnh
- [ ] Empty/fallback state gọn

## Notifications
- [ ] Dùng dữ liệu DB thật
- [ ] Realtime notification hoạt động đúng
- [ ] Mark all as read hoạt động đúng
- [ ] Unread/read style rõ ràng
- [ ] Empty/fallback state gọn

## Profile
- [ ] Dùng dữ liệu DB thật
- [ ] Post list hoạt động đúng
- [ ] Avatar/cover/media hiển thị ổn
- [ ] Empty/fallback state gọn

## Dashboard
- [ ] Layout dashboard riêng hoàn toàn
- [ ] Dữ liệu thống kê đúng
- [ ] Không lẫn social shell

## UI System
- [ ] Theme sáng gọn, ít chữ thừa
- [ ] Hover states đầy đủ
- [ ] Popup/toast/alert style đầy đủ
- [ ] Không còn text kiểu demo/sample
- [ ] Responsive desktop/tablet/mobile ổn
- [ ] Không bị tràn ngang

## Final QA
- [x] Build pass
- [x] Login pass
- [x] Feed pass
- [ ] Friends pass
- [ ] Groups pass
- [ ] Chat pass
- [ ] Notifications pass
- [ ] Profile pass
- [ ] Dashboard pass
