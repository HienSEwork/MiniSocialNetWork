using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Infrastructure.Repositories.Interfaces;

public interface IGroupRepository
{
    Task<PagedResult<Group>> SearchAsync(GroupQuery query);
    Task<List<Group>> GetAllAsync();
    Task<Group> GetByIdAsync(Guid id);
    Task AddAsync(Group group);
    Task SaveChangesAsync();
}