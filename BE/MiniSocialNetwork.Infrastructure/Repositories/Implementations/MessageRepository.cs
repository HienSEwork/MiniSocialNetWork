using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public sealed class MessageRepository : IMessageRepository
{
    private readonly AppDbContext _context;
    public MessageRepository(AppDbContext context) => _context = context;

    public Task<List<Message>> GetPrivateHistoryAsync(string firstUserId, string secondUserId, int take)
        => _context.Messages
            .Where(message => !message.IsGroupMessage &&
                ((message.SenderId == firstUserId && message.ReceiverId == secondUserId) ||
                 (message.SenderId == secondUserId && message.ReceiverId == firstUserId)))
            .Include(message => message.Sender)
            .OrderByDescending(message => message.CreatedDate)
            .Take(Math.Clamp(take, 1, 200))
            .OrderBy(message => message.CreatedDate)
            .ToListAsync();

    public Task<List<Message>> GetGroupHistoryAsync(Guid groupId, int take)
        => _context.Messages
            .Where(message => message.IsGroupMessage && message.GroupId == groupId)
            .Include(message => message.Sender)
            .OrderByDescending(message => message.CreatedDate)
            .Take(Math.Clamp(take, 1, 200))
            .OrderBy(message => message.CreatedDate)
            .ToListAsync();

    public Task AddAsync(Message message) => _context.Messages.AddAsync(message).AsTask();
    public Task SaveChangesAsync() => _context.SaveChangesAsync();
}
