using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IMessageRepository
{
    Task<List<Message>> GetPrivateHistoryAsync(string firstUserId, string secondUserId, int take);
    Task<List<Message>> GetGroupHistoryAsync(Guid groupId, int take);
    Task AddAsync(Message message);
    Task SaveChangesAsync();
}
