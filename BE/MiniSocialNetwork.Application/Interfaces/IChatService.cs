using MiniSocialNetwork.Application.DTOs.Chat;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IChatService
{
    Task<IReadOnlyCollection<ChatUserResponse>> GetUsersAsync(string currentUserId, string? keyword);
    Task<MessageResponse> SendAsync(string senderId, SendMessageRequest request);
    Task<IReadOnlyCollection<MessageResponse>> GetPrivateHistoryAsync(string currentUserId, string otherUserId, int take = 100);
    Task<IReadOnlyCollection<MessageResponse>> GetGroupHistoryAsync(string currentUserId, Guid groupId, int take = 100);
    Task EnsureGroupMemberAsync(Guid groupId, string userId);
}
