using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IGroupRepository
{
    Task<List<Group>> GetAllAsync();
    Task<Group> GetByIdAsync(Guid id);
    Task AddAsync(Group group);
    Task SaveChangesAsync();
}