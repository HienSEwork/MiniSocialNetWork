using MiniSocialNetwork.Application.DTOs.Group;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IGroupService
{
    Task<Guid> CreateGroupAsync(CreateGroupRequest request, string userId);
    Task JoinGroupAsync(Guid groupId, string userId);
    Task LeaveGroupAsync(Guid groupId, string userId);
    Task<List<GroupResponse>> GetAllAsync();
}