using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface ICommentRepository
{
    Task<List<Comment>> GetByPostAsync(Guid postId);
    Task<Comment?> GetByIdAsync(Guid id);
    Task AddAsync(Comment comment);
    void Remove(Comment comment);
    Task SaveChangesAsync();
}
