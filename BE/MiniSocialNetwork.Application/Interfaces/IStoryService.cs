using MiniSocialNetwork.Application.DTOs.Story;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IStoryService
{
    Task<List<StoryResponse>> GetActiveAsync(string userId);
    Task<StoryResponse> GetByIdAsync(Guid id, string userId);
    Task<Guid> CreateAsync(CreateStoryRequest request, string userId);
    Task UpdateAsync(Guid id, CreateStoryRequest request, string userId);
    Task DeleteAsync(Guid id, string userId);
    Task<StoryResponse> ReactAsync(Guid id, int type, string userId);
    Task<string> GetAuthorIdAsync(Guid id);
}
