using Microsoft.EntityFrameworkCore;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.DAL.Repositories;

public class ChatRepository(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IChatRepository
{
    public async Task<IReadOnlyList<Message>> GetPrivateConversationAsync(string currentUserId, string otherUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Messages
            .AsNoTracking()
            .Include(message => message.Sender)
            .Where(message => !message.IsGroupMessage &&
                              ((message.SenderId == currentUserId && message.ReceiverId == otherUserId) ||
                               (message.SenderId == otherUserId && message.ReceiverId == currentUserId)))
            .OrderBy(message => message.CreatedDate)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<Message>> GetGroupConversationAsync(Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Messages
            .AsNoTracking()
            .Include(message => message.Sender)
            .Where(message => message.IsGroupMessage && message.GroupId == groupId)
            .OrderBy(message => message.CreatedDate)
            .ToListAsync();
    }

    public async Task<bool> IsUserMemberOfGroupAsync(string userId, Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.GroupMembers.AnyAsync(member => member.GroupId == groupId && member.UserId == userId);
    }

    public async Task AddMessageAsync(Message message)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        dbContext.Messages.Add(message);
        await dbContext.SaveChangesAsync();
    }

    public async Task<ApplicationUser> GetRequiredUserAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Users.FirstAsync(user => user.Id == userId);
    }
}
