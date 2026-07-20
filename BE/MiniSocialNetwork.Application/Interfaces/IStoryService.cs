using MiniSocialNetwork.Application.DTOs.Story;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IStoryService
{
    Task<List<StoryResponse>> GetActiveAsync();
    Task<StoryResponse> GetByIdAsync(Guid id);
    Task<Guid> CreateAsync(CreateStoryRequest request, string userId);
    Task UpdateAsync(Guid id, CreateStoryRequest request, string userId);
    Task DeleteAsync(Guid id, string userId);
}
