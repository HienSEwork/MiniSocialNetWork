using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IReactionRepository
{
    Task<List<Reaction>> GetByPostAsync(Guid postId);
    Task<Reaction?> GetUserReactionAsync(Guid postId, string userId);
    Task AddAsync(Reaction reaction);
    void Remove(Reaction reaction);
    Task SaveChangesAsync();
}
