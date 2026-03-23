# WebBuildRule

## Nguyên tắc làm việc
- [x] Trả lời ngắn gọn, tập trung công việc.
- [x] Không lan man ý tưởng khi user yêu cầu sửa trực tiếp.
- [x] Ưu tiên sửa code thật trong project, không dùng HTML tạm ngoài luồng.
- [x] Khi sửa UI phải giữ logic và dữ liệu hiện có nếu không có yêu cầu khác.
- [x] Sau mỗi lỗi chức năng phải fix tận gốc trong code, không vá tạm ở giao diện.

## Yêu cầu UI đã chốt
- [x] Home chỉ còn 1 layout duy nhất cho cả guest và logged-in.
- [x] Home dùng dark theme đồng bộ.
- [x] Nền tối đã làm sáng hơn để không che nội dung.
- [x] Topbar, card, feed, rail phải cùng hệ màu.
- [ ] Tiếp tục tinh chỉnh toàn bộ page còn lại theo cùng style nếu user yêu cầu.

## Rác cần tránh
- [x] Đã xóa file HTML rác ngoài source.
- [x] Không tạo thêm file HTML test ở root project.
- [ ] Nếu cần ảnh kiểm tra, chỉ lưu trong `artifacts` và xóa khi user yêu cầu.

## Fix chức năng đã làm
- [x] Logout luôn chuyển về `/Account/Login`.
- [x] Bỏ layout guest riêng trong `MainLayout`.
- [x] Home guest và home logged-in dùng chung 1 khung giao diện.

## File đã sửa gần nhất
- [x] `src/SocialNetwork.Web/wwwroot/app.css`
- [x] `src/SocialNetwork.Web/Components/Pages/Home.razor`
- [x] `src/SocialNetwork.Web/Components/Layout/MainLayout.razor`
- [x] `src/SocialNetwork.Web/Components/Layout/NavMenu.razor`
- [x] `src/SocialNetwork.Web/Components/Account/IdentityComponentsEndpointRouteBuilderExtensions.cs`

## Checklist trước khi kết thúc
- [x] Build lại project web.
- [x] Test logout.
- [x] Test guest home.
- [x] Test logged-in home.
