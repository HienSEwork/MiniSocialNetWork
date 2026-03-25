using SocialNetwork.DAL.Entities;

namespace SocialNetwork.DAL.Repositories;

public interface IChatRepository
{
    Task<IReadOnlyList<Message>> GetPrivateConversationAsync(string currentUserId, string otherUserId);

    Task<IReadOnlyList<Message>> GetGroupConversationAsync(Guid groupId);

    Task<bool> IsUserMemberOfGroupAsync(string userId, Guid groupId);

    Task AddMessageAsync(Message message);

    Task<ApplicationUser> GetRequiredUserAsync(string userId);
}
