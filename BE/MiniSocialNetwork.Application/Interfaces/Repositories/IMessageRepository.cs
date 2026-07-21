using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IMessageRepository
{
    Task AddAsync(Message message);
    Task SaveChangesAsync();
    Task<List<Message>> GetPrivateHistoryAsync(string userAId, string userBId, int limit = 50);
    Task<List<Message>> GetGroupHistoryAsync(Guid groupId, int limit = 100);
}
