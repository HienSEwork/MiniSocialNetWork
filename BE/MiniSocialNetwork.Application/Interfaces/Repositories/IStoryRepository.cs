using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IStoryRepository
{
    Task<List<Story>> GetActiveAsync();
    Task<Story?> GetByIdAsync(Guid id);
    Task AddAsync(Story story);
    Task SaveChangesAsync();
}
