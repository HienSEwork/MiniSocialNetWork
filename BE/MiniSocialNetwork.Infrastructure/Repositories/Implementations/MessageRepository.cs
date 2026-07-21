using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public class MessageRepository : IMessageRepository
{
    private readonly AppDbContext _db;

    public MessageRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(Message message)
    {
        await _db.Messages.AddAsync(message);
    }

    public async Task SaveChangesAsync()
    {
        await _db.SaveChangesAsync();
    }

    public async Task<List<Message>> GetPrivateHistoryAsync(string userAId, string userBId, int limit = 50)
    {
        // messages between two users (either direction)
        return await _db.Messages
            .AsNoTracking()
            .Where(m => !m.IsGroupMessage &&
                   ((m.SenderId == userAId && m.ReceiverId == userBId) ||
                    (m.SenderId == userBId && m.ReceiverId == userAId)))
            .OrderByDescending(m => m.CreatedDate)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<List<Message>> GetGroupHistoryAsync(Guid groupId, int limit = 100)
    {
        return await _db.Messages
            .AsNoTracking()
            .Where(m => m.IsGroupMessage && m.GroupId == groupId)
            .OrderByDescending(m => m.CreatedDate)
            .Take(limit)
            .ToListAsync();
    }
}
