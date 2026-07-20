using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.DTOs.Chat;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public sealed class ChatService : IChatService
{
    private readonly IMessageRepository _messageRepository;
    private readonly IGroupRepository _groupRepository;
    private readonly UserManager<AppUser> _userManager;

    public ChatService(IMessageRepository messageRepository, IGroupRepository groupRepository, UserManager<AppUser> userManager)
    {
        _messageRepository = messageRepository;
        _groupRepository = groupRepository;
        _userManager = userManager;
    }

    public async Task<IReadOnlyCollection<ChatUserResponse>> GetUsersAsync(string currentUserId, string? keyword)
    {
        var query = _userManager.Users.Where(user => !user.IsDeleted && user.Id != currentUserId);
        if (!string.IsNullOrWhiteSpace(keyword))
            query = query.Where(user => user.DisplayName.Contains(keyword) || (user.Email != null && user.Email.Contains(keyword)));
        return await query.OrderBy(user => user.DisplayName).Take(50)
            .Select(user => new ChatUserResponse
            {
                Id = user.Id, DisplayName = user.DisplayName, AvatarUrl = user.AvatarUrl, Bio = user.Bio
            }).ToListAsync();
    }

    public async Task<MessageResponse> SendAsync(string senderId, SendMessageRequest request)
    {
        ValidateContent(request.Content);
        var isGroup = request.GroupId.HasValue;
        if (isGroup == !string.IsNullOrWhiteSpace(request.ReceiverId))
            throw new ArgumentException("Provide either receiverId or groupId");

        if (isGroup)
            await EnsureGroupMemberAsync(request.GroupId!.Value, senderId);
        else
        {
            var receiver = await _userManager.FindByIdAsync(request.ReceiverId!);
            if (receiver == null || receiver.IsDeleted) throw new KeyNotFoundException("Receiver not found");
            if (receiver.Id == senderId) throw new ArgumentException("Cannot send a private message to yourself");
        }

        var message = new Message
        {
            Id = Guid.NewGuid(), SenderId = senderId, ReceiverId = isGroup ? null : request.ReceiverId,
            GroupId = request.GroupId, Content = request.Content.Trim(), CreatedDate = DateTime.UtcNow,
            IsGroupMessage = isGroup
        };
        await _messageRepository.AddAsync(message);
        await _messageRepository.SaveChangesAsync();
        var sender = await _userManager.FindByIdAsync(senderId);
        message.Sender = sender!;
        return Map(message);
    }

    public async Task<IReadOnlyCollection<MessageResponse>> GetPrivateHistoryAsync(string currentUserId, string otherUserId, int take = 100)
    {
        if (await _userManager.FindByIdAsync(otherUserId) == null) throw new KeyNotFoundException("User not found");
        return (await _messageRepository.GetPrivateHistoryAsync(currentUserId, otherUserId, take)).Select(Map).ToArray();
    }

    public async Task<IReadOnlyCollection<MessageResponse>> GetGroupHistoryAsync(string currentUserId, Guid groupId, int take = 100)
    {
        await EnsureGroupMemberAsync(groupId, currentUserId);
        return (await _messageRepository.GetGroupHistoryAsync(groupId, take)).Select(Map).ToArray();
    }

    public async Task EnsureGroupMemberAsync(Guid groupId, string userId)
    {
        var group = await _groupRepository.GetByIdAsync(groupId);
        if (group == null || group.IsDeleted) throw new KeyNotFoundException("Group not found");
        if (!group.Members.Any(member => member.UserId == userId))
            throw new UnauthorizedAccessException("Only group members can access group chat");
    }

    private static void ValidateContent(string content)
    {
        if (string.IsNullOrWhiteSpace(content)) throw new ArgumentException("Message is required");
        if (content.Length > 2000) throw new ArgumentException("Message is too long");
    }

    private static MessageResponse Map(Message message) => new()
    {
        Id = message.Id, SenderId = message.SenderId,
        SenderName = message.Sender?.DisplayName ?? "Member", SenderAvatarUrl = message.Sender?.AvatarUrl,
        ReceiverId = message.ReceiverId, GroupId = message.GroupId, Content = message.Content,
        CreatedDate = message.CreatedDate, IsGroupMessage = message.IsGroupMessage
    };
}
