using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces;

public interface ITokenService
{
    Task<(string Token, DateTime ExpiresAt)> CreateAsync(AppUser user);
}
