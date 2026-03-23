using Microsoft.EntityFrameworkCore;
using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.BLL.Services;

public class ChatService(IDbContextFactory<ApplicationDbContext> dbContextFactory, IFriendshipService friendshipService) : IChatService
{
    public async Task<IReadOnlyList<UserSummaryDto>> GetChatUsersAsync(string currentUserId)
    {
        return await friendshipService.GetFriendsAsync(currentUserId);
    }

    public async Task<IReadOnlyList<MessageDto>> GetPrivateConversationAsync(string currentUserId, string otherUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        if (!await friendshipService.AreFriendsAsync(currentUserId, otherUserId))
        {
            throw new InvalidOperationException("Chỉ có thể nhắn tin riêng với người đã kết bạn.");
        }

        return await dbContext.Messages
            .AsNoTracking()
            .Include(message => message.Sender)
            .Where(message => !message.IsGroupMessage &&
                              ((message.SenderId == currentUserId && message.ReceiverId == otherUserId) ||
                               (message.SenderId == otherUserId && message.ReceiverId == currentUserId)))
            .OrderBy(message => message.CreatedDate)
            .ToListAsync()
            .ContinueWith(task => (IReadOnlyList<MessageDto>)task.Result.Select(message => MapMessage(message, currentUserId)).ToList());
    }

    public async Task<IReadOnlyList<MessageDto>> GetGroupConversationAsync(string currentUserId, Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var isMember = await dbContext.GroupMembers.AnyAsync(member => member.GroupId == groupId && member.UserId == currentUserId);
        if (!isMember)
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi mở chat nhóm.");
        }

        var messages = await dbContext.Messages
            .AsNoTracking()
            .Include(message => message.Sender)
            .Where(message => message.IsGroupMessage && message.GroupId == groupId)
            .OrderBy(message => message.CreatedDate)
            .ToListAsync();

        return messages.Select(message => MapMessage(message, currentUserId)).ToList();
    }

    public async Task<MessageDto> SavePrivateMessageAsync(string senderId, string receiverId, string content)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("Nội dung tin nhắn là bắt buộc.");
        }

        if (!await friendshipService.AreFriendsAsync(senderId, receiverId))
        {
            throw new InvalidOperationException("Chỉ có thể nhắn tin riêng với người đã kết bạn.");
        }

        var message = new Message
        {
            SenderId = senderId,
            ReceiverId = receiverId,
            Content = content.Trim(),
            IsGroupMessage = false
        };

        dbContext.Messages.Add(message);
        await dbContext.SaveChangesAsync();

        var sender = await dbContext.Users.FirstAsync(user => user.Id == senderId);
        message.Sender = sender;
        return MapMessage(message, senderId);
    }

    public async Task<MessageDto> SaveGroupMessageAsync(string senderId, Guid groupId, string content)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("Nội dung tin nhắn là bắt buộc.");
        }

        var isMember = await dbContext.GroupMembers.AnyAsync(member => member.GroupId == groupId && member.UserId == senderId);
        if (!isMember)
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi gửi tin nhắn.");
        }

        var message = new Message
        {
            SenderId = senderId,
            GroupId = groupId,
            Content = content.Trim(),
            IsGroupMessage = true
        };

        dbContext.Messages.Add(message);
        await dbContext.SaveChangesAsync();

        var sender = await dbContext.Users.FirstAsync(user => user.Id == senderId);
        message.Sender = sender;
        return MapMessage(message, senderId);
    }

    private static MessageDto MapMessage(Message message, string currentUserId) =>
        new(
            message.Id,
            message.SenderId,
            string.IsNullOrWhiteSpace(message.Sender.DisplayName) ? message.Sender.Email ?? message.Sender.UserName ?? "Người dùng" : message.Sender.DisplayName,
            message.Sender.AvatarUrl,
            message.ReceiverId,
            message.GroupId,
            message.Content,
            message.CreatedDate,
            message.SenderId == currentUserId,
            message.IsGroupMessage);
}
