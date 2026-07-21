import 'package:flutter/widgets.dart';

class AppCopy {
  const AppCopy._(this._english);

  final bool _english;
  bool get isEnglish => _english;

  static AppCopy of(BuildContext context) =>
      AppCopy._(Localizations.localeOf(context).languageCode == 'en');

  String get feed => _english ? 'Feed' : 'Bảng tin';
  String get groups => _english ? 'Groups' : 'Nhóm';
  String get chat => _english ? 'Chat' : 'Trò chuyện';
  String get activity => _english ? 'Activity' : 'Hoạt động';
  String get profile => _english ? 'Profile' : 'Cá nhân';
  String get app => _english ? 'App' : 'Ứng dụng';
  String get darkMode => _english ? 'Dark mode' : 'Giao diện tối';
  String get darkModeHint => _english
      ? 'Your choice is saved on this device'
      : 'Lựa chọn được lưu trên thiết bị này';
  String get language => _english ? 'Language' : 'Ngôn ngữ';
  String get vietnamese => _english ? 'Vietnamese' : 'Tiếng Việt';
  String get english => _english ? 'English' : 'Tiếng Anh';
  String get editProfile => _english ? 'Edit profile' : 'Chỉnh sửa hồ sơ';
  String get chooseImage =>
      _english ? 'Choose image from device' : 'Chọn ảnh từ máy';
  String get displayName => _english ? 'Display name' : 'Tên hiển thị';
  String get bio => _english ? 'Bio' : 'Tiểu sử';
  String get saveChanges => _english ? 'Save changes' : 'Lưu thay đổi';
  String get signOut => _english ? 'Sign out' : 'Đăng xuất';
  String get exploreMode =>
      _english ? 'Browsing as a guest' : 'Đang ở chế độ khám phá';
  String get member => _english ? 'TechNet member' : 'Thành viên TechNet';
  String get profileUpdated =>
      _english ? 'Profile updated.' : 'Đã cập nhật hồ sơ.';
  String get uploadFailed =>
      _english ? 'Could not upload the image.' : 'Không thể tải ảnh lên.';
  String get loginToEdit => _english
      ? 'Please sign in to edit your profile.'
      : 'Hãy đăng nhập để chỉnh sửa hồ sơ.';

  String get search => _english ? 'Search' : 'Tìm kiếm';
  String get retry => _english ? 'Try again' : 'Thử lại';
  String get close => _english ? 'Close' : 'Đóng';
  String get back => _english ? 'Back' : 'Quay lại';
  String get understood => _english ? 'Got it' : 'Đã hiểu';
  String unavailable(String feature) => _english
      ? '$feature is coming soon.'
      : '$feature là tính năng sắp ra mắt.';

  String get communityFallback => _english ? 'Community' : 'Cộng đồng';
  String minutesAgo(int value) => _english ? '${value}m ago' : '$value phút';
  String hoursAgo(int value) => _english ? '${value}h ago' : '$value giờ';
  String daysAgo(int value) => _english ? '${value}d ago' : '$value ngày';
  String get justNow => _english ? 'Just now' : 'Vừa xong';
  String get mediaLoadFailed => _english
      ? 'Could not load media'
      : 'Không tải được nội dung đa phương tiện';
  String get startConversation =>
      _english ? 'Start the conversation' : 'Hãy bắt đầu cuộc trò chuyện';
  String get gettingAttention =>
      _english ? 'Getting attention' : 'Đang được quan tâm';
  String get react => _english ? 'React' : 'Cảm xúc';
  String get comment => _english ? 'Comment' : 'Bình luận';
  String get share => _english ? 'Share' : 'Chia sẻ';
  String get like => _english ? 'Like' : 'Thích';
  String get love => _english ? 'Love' : 'Yêu thích';
  String get editPost => _english ? 'Edit post' : 'Sửa bài viết';
  String get postContent => _english ? 'Post content' : 'Nội dung bài viết';
  String get uploadedMedia => _english ? 'Uploaded media' : 'Media đã upload';
  String get postUpdated =>
      _english ? 'Post updated.' : 'Đã cập nhật bài viết.';
  String get comments => _english ? 'Comments' : 'Bình luận';
  String get commentsLoadFailed =>
      _english ? 'Could not load comments' : 'Chưa tải được bình luận';
  String get noComments => _english ? 'No comments yet' : 'Chưa có bình luận';
  String get firstComment => _english
      ? 'Be the first to join the conversation.'
      : 'Hãy là người đầu tiên tham gia cuộc trò chuyện.';
  String get writeComment =>
      _english ? 'Write a comment...' : 'Viết bình luận...';

  String get homeActive =>
      _english ? 'Community is active' : 'Cộng đồng đang hoạt động';
  String get homeRefreshing =>
      _english ? 'Refreshing feed' : 'Đang làm mới bảng tin';
  String get trendingNow => _english ? 'Trending now' : 'Đang được quan tâm';
  String get featuredPost =>
      _english ? 'Featured tech story' : 'Bài viết công nghệ nổi bật';
  String get topGroups => _english ? 'Top active groups' : 'Nhóm tương tác cao';
  String get topSignal => _english ? 'High engagement' : 'Tương tác cao';
  String get groupUnit => _english ? 'groups' : 'nhóm';
  String newPostCount(int count) =>
      _english ? '$count new posts' : '$count bài mới';
  String engagementCount(int count) =>
      _english ? '$count interactions' : '$count tương tác';
  String memberCount(int count) =>
      _english ? '$count members' : '$count thành viên';
  String postCount(int count) => _english ? '$count posts' : '$count bài';
  String get feedLoadFailed =>
      _english ? 'Could not load the feed' : 'Không thể tải bảng tin';
  String get feedEmptyTitle => _english
      ? 'The feed is waiting for its first story'
      : 'Bảng tin đang đợi câu chuyện đầu tiên';
  String get feedEmptyNoGroups => _english
      ? 'Create a group to start your community.'
      : 'Tạo một nhóm để bắt đầu cộng đồng của bạn.';
  String get feedEmptyHasGroups => _english
      ? 'Use the composer above and share what you care about.'
      : 'Chọn ô viết bài ở trên và chia sẻ điều bạn đang quan tâm.';
  String get latestCommunity =>
      _english ? 'Latest in the community' : 'Mới trong cộng đồng';
  String get topPosts => _english ? 'Top posts' : 'Bài viết tương tác cao';
  String get composerEnabled =>
      _english ? 'What would you like to share?' : 'Bạn muốn chia sẻ điều gì?';
  String get composerDisabled => _english
      ? 'Create a group before posting'
      : 'Tạo nhóm trước khi đăng bài';
  String get shareWithCommunity =>
      _english ? 'Share with the community' : 'Chia sẻ với cộng đồng';
  String get shareWithCommunityHint => _english
      ? 'Choose a group and share what is on your mind.'
      : 'Chọn nhóm và chia sẻ điều bạn đang nghĩ.';
  String get postInGroup => _english ? 'Post in group' : 'Đăng trong nhóm';
  String get writeThought => _english
      ? 'Write what you are thinking...'
      : 'Viết điều bạn đang nghĩ...';
  String get imagePathOptional =>
      _english ? 'Image path (optional)' : 'Đường dẫn ảnh (không bắt buộc)';
  String postedTo(String group) =>
      _english ? 'Posted to $group.' : 'Đã đăng bài vào $group.';
  String get publishPost => _english ? 'Post' : 'Đăng bài';

  String get groupsTitle => _english ? 'Your spaces' : 'Không gian của bạn';
  String get groupsSubtitle => _english
      ? 'Find people with shared interests.'
      : 'Tìm người cùng mối quan tâm.';
  String get createGroup => _english ? 'Create group' : 'Tạo nhóm';
  String get searchGroupHint =>
      _english ? 'Search by group name' : 'Tìm theo tên nhóm';
  String get groupsLoadFailed =>
      _english ? 'Could not load groups' : 'Không tải được danh sách nhóm';
  String get noGroupsTitle => _english
      ? 'No matching communities yet'
      : 'Chưa tìm thấy cộng đồng phù hợp';
  String get noGroupsMessage => _english
      ? 'Try another keyword or create your first group.'
      : 'Thử từ khóa khác hoặc tạo nhóm đầu tiên của bạn.';
  String get createGroupTitle =>
      _english ? 'Create a new space' : 'Tạo một không gian mới';
  String get createGroupHint => _english
      ? 'Use a clear name so people know who they will meet and what they will discuss.'
      : 'Đặt một cái tên rõ ràng để mọi người biết họ sẽ gặp ai và nói về điều gì.';
  String get groupName => _english ? 'Group name' : 'Tên nhóm';
  String get shortDescription => _english ? 'Short description' : 'Mô tả ngắn';
  String get newCommunityDescription => _english
      ? 'A new community is waiting to be explored.'
      : 'Một cộng đồng mới đang chờ bạn khám phá.';
  String get editGroup => _english ? 'Edit group' : 'Sửa nhóm';
  String get groupUpdated => _english ? 'Group updated.' : 'Đã cập nhật nhóm.';
  String get groupPostsLoadFailed =>
      _english ? 'Could not load posts' : 'Không tải được bài viết';
  String get noGroupPosts =>
      _english ? 'No posts in this group yet' : 'Nhóm chưa có bài viết';
  String get firstGroupPost => _english
      ? 'Start with a useful share.'
      : 'Hãy mở đầu bằng một chia sẻ hữu ích.';
  String get newCommunityOnTechNet => _english
      ? 'A new community on TechNet.'
      : 'Một cộng đồng mới trên TechNet.';
  String joinedGroup(String group) =>
      _english ? 'Joined $group.' : 'Đã tham gia $group.';
  String get join => _english ? 'Join' : 'Tham gia';
  String get writePost => _english ? 'Write post' : 'Viết bài';

  String get searchHint => _english
      ? 'Search people, groups, or posts'
      : 'Tìm người, nhóm hoặc bài viết';
  String get clearSearch => _english ? 'Clear keyword' : 'Xóa từ khóa';
  String get personDefaultBio => _english
      ? 'A member of the TechNet community.'
      : 'Thành viên của cộng đồng TechNet.';
  String get all => _english ? 'All' : 'Tất cả';
  String get people => _english ? 'People' : 'Mọi người';
  String get posts => _english ? 'Posts' : 'Bài viết';
  String get exploreCommunity =>
      _english ? 'Explore the whole community' : 'Khám phá cả cộng đồng';
  String get searchPrompt => _english
      ? 'Enter at least 2 characters to search people, groups, and stories.'
      : 'Nhập ít nhất 2 ký tự để tìm người, nhóm và câu chuyện.';
  String get searchFailed =>
      _english ? 'Could not search' : 'Chưa thể tìm kiếm';
  String get noSearchResults =>
      _english ? 'No matching results yet' : 'Chưa có kết quả phù hợp';
  String get noSearchResultsHint => _english
      ? 'Try another keyword or switch back to All.'
      : 'Thử một từ khóa khác hoặc chọn mục Tất cả.';
  String resultCount(int count) =>
      _english ? '$count results' : '$count kết quả';

  String get loginRequiredForChat =>
      _english ? 'Sign in to message' : 'Đăng nhập để nhắn tin';
  String get loginRequiredForChatHint => _english
      ? 'Private and group chat use JWT to protect conversations.'
      : 'Chat riêng tư và chat nhóm sử dụng JWT để bảo vệ cuộc trò chuyện.';
  String get chatSearchHint =>
      _english ? 'Find someone to message' : 'Tìm người để trò chuyện';
  String get contactsLoadFailed =>
      _english ? 'Could not load contacts' : 'Chưa tải được danh bạ';
  String get noContacts => _english ? 'No one is here yet' : 'Chưa có ai ở đây';
  String get noContactsHint => _english
      ? 'When more members join, you can start private conversations.'
      : 'Khi có thêm thành viên, bạn có thể bắt đầu cuộc trò chuyện riêng tư.';
  String get startPrivateChat =>
      _english ? 'Start a conversation' : 'Bắt đầu một cuộc trò chuyện';
  String get conversation => _english ? 'Conversation' : 'Trò chuyện';
  String get conversationOpenFailed =>
      _english ? 'Could not open conversation' : 'Chưa mở được trò chuyện';
  String get messageHint =>
      _english ? 'Type something...' : 'Nhắn điều gì đó...';

  String get realtimeActive => _english
      ? 'Receiving updates in real time.'
      : 'Đang nhận cập nhật theo thời gian thực.';
  String get realtimeWaiting => _english
      ? 'Will reconnect when you sign in.'
      : 'Sẽ tự kết nối khi bạn đăng nhập.';
  String get activityEmptyTitle =>
      _english ? 'You are all caught up' : 'Bạn đã xem hết rồi';
  String get activityEmptyHint => _english
      ? 'Reactions, comments, and new activity will appear here.'
      : 'Reaction, bình luận và hoạt động mới sẽ xuất hiện tại đây.';
  String get newReaction =>
      _english ? 'New reaction on a post' : 'Bài viết có cảm xúc mới';
  String get newComment =>
      _english ? 'New comment on a post' : 'Có bình luận mới trên bài viết';
  String get justReceived => _english
      ? 'Just received from NotificationHub'
      : 'Vừa nhận từ NotificationHub';

  String get welcomeBack => _english ? 'Welcome back' : 'Chào bạn trở lại';
  String get loginSubtitle => _english
      ? 'Sign in to continue your conversations.'
      : 'Đăng nhập để tiếp tục câu chuyện của bạn.';
  String get password => _english ? 'Password' : 'Mật khẩu';
  String get showPassword => _english ? 'Show password' : 'Hiện mật khẩu';
  String get hidePassword => _english ? 'Hide password' : 'Ẩn mật khẩu';
  String get forgotPassword => _english ? 'Forgot password?' : 'Quên mật khẩu?';
  String get login => _english ? 'Sign in' : 'Đăng nhập';
  String get or => _english ? 'or' : 'hoặc';
  String get exploreAsGuest =>
      _english ? 'Explore without signing in' : 'Khám phá không cần đăng nhập';
  String get noAccount => _english ? 'No account yet?' : 'Chưa có tài khoản?';
  String get createAccount => _english ? 'Create account' : 'Tạo tài khoản';
  String get createProfile =>
      _english ? 'Create your profile' : 'Tạo hồ sơ của bạn';
  String get registerSubtitle => _english
      ? 'A real name, a better community.'
      : 'Một cái tên thật, một cộng đồng phù hợp.';
  String get passwordHelp =>
      _english ? 'At least 6 characters' : 'Tối thiểu 6 ký tự';
  String get registerSuccess => _english
      ? 'Account created. Please sign in.'
      : 'Tạo tài khoản thành công. Hãy đăng nhập.';
  String get safeUseNote => _english
      ? 'By continuing, you agree to use TechNet respectfully and safely.'
      : 'Khi tiếp tục, bạn đồng ý sử dụng TechNet một cách tôn trọng và an toàn.';

  String get authMissingFields => _english
      ? 'Please enter email and password.'
      : 'Vui lòng nhập email và mật khẩu.';
  String get badLoginShape => _english
      ? 'The login response from the backend has an unexpected format.'
      : 'Phản hồi đăng nhập từ backend chưa đúng định dạng.';
  String get loginApiMissing => _english
      ? 'The backend has not implemented login yet. You can use guest mode.'
      : 'Backend chưa triển khai API đăng nhập. Bạn có thể vào chế độ khám phá.';
  String get displayNameTooShort => _english
      ? 'Display name needs at least 2 characters.'
      : 'Tên hiển thị cần ít nhất 2 ký tự.';
  String get invalidEmail =>
      _english ? 'Email is not valid.' : 'Email chưa đúng định dạng.';
  String get passwordTooShort => _english
      ? 'Password needs at least 6 characters.'
      : 'Mật khẩu cần ít nhất 6 ký tự.';
  String get registerApiMissing => _english
      ? 'The backend has not implemented registration yet.'
      : 'Backend chưa triển khai API đăng ký.';
  String get guestName => _english ? 'Guest explorer' : 'Khách khám phá';
  String get loginToUploadAvatar => _english
      ? 'Please sign in to update your avatar.'
      : 'Hãy đăng nhập để cập nhật ảnh đại diện.';
}
