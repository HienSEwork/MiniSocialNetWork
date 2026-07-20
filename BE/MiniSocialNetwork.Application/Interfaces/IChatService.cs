namespace MiniSocialNetwork.Application.Interfaces;

using MiniSocialNetwork.Application.DTOs.Chat;

public interface IChatService
{
    Task<MessageDto> SendMessageAsync(string senderId, string? receiverId, Guid? groupId, string content, bool isGroupMessage);
    Task<List<MessageDto>> GetPrivateHistoryAsync(string userAId, string userBId, int limit = 50);
    Task<List<MessageDto>> GetGroupHistoryAsync(Guid groupId, int limit = 100);
}
