using MiniSocialNetwork.Application.DTOs.Group;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IGroupRepository
{
    Task<PagedResult<Group>> SearchAsync(GroupQuery query);
    Task<List<Group>> GetAllAsync();
    Task<List<Group>> GetJoinedAsync(string userId);
    Task<Group?> GetByIdAsync(Guid id);
    Task AddAsync(Group group);
    Task SaveChangesAsync();
}
