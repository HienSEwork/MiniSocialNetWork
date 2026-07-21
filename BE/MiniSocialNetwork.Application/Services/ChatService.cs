using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.DTOs.Chat;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public class ChatService : IChatService
{
    private readonly IMessageRepository _repo;

    public ChatService(IMessageRepository repo)
    {
        _repo = repo;
    }

    public async Task<MessageDto> SendMessageAsync(string senderId, string? receiverId, Guid? groupId, string content, bool isGroupMessage)
    {
        if (string.IsNullOrWhiteSpace(content))
            throw new ArgumentException("Message content is required", nameof(content));

        var message = new Message
        {
            Id = Guid.NewGuid(),
            SenderId = senderId,
            ReceiverId = receiverId,
            GroupId = groupId,
            Content = content.Trim(),
            CreatedDate = DateTime.UtcNow,
            IsGroupMessage = isGroupMessage
        };

        await _repo.AddAsync(message);
        await _repo.SaveChangesAsync();

        return Map(message);
    }

    public async Task<List<MessageDto>> GetPrivateHistoryAsync(string userAId, string userBId, int limit = 50)
    {
        var messages = await _repo.GetPrivateHistoryAsync(userAId, userBId, limit);
        return messages.OrderBy(m => m.CreatedDate).Select(Map).ToList();
    }

    public async Task<List<MessageDto>> GetGroupHistoryAsync(Guid groupId, int limit = 100)
    {
        var messages = await _repo.GetGroupHistoryAsync(groupId, limit);
        return messages.OrderBy(m => m.CreatedDate).Select(Map).ToList();
    }

    private static MessageDto Map(Message m) => new()
    {
        Id = m.Id,
        SenderId = m.SenderId,
        ReceiverId = m.ReceiverId,
        GroupId = m.GroupId,
        Content = m.Content,
        CreatedDate = m.CreatedDate,
        IsGroupMessage = m.IsGroupMessage
    };
}
