using MiniSocialNetwork.Application.DTOs.Comment;

namespace MiniSocialNetwork.Application.Interfaces;

public interface ICommentService
{
    Task<IReadOnlyCollection<CommentResponse>> GetByPostAsync(Guid postId);
    Task<CommentResponse> CreateAsync(Guid postId, CommentRequest request, string userId);
    Task<CommentResponse> UpdateAsync(Guid commentId, CommentRequest request, string userId);
    Task DeleteAsync(Guid commentId, string userId);
}
