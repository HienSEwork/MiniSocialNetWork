using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Application.DTOs.Friend;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IFriendRepository
{
    Task<FriendRequest?> GetByIdAsync(Guid id);
    Task<FriendRequest?> GetPendingBetweenAsync(string userA, string userB);
    Task<FriendRequest?> GetLatestBetweenAsync(string requesterId, string addresseeId);
    Task AddAsync(FriendRequest request);
    Task SaveChangesAsync();
    Task<List<FriendRequest>> GetIncomingRequestsAsync(string userId);
    Task<List<AppUser>> GetFriendsAsync(string userId, int take = 200);
    Task<List<FriendRequest>> GetBetweenAnyDirectionAsync(string userA, string userB);
    Task RemoveFriendshipAsync(string userA, string userB);
    Task<List<RecommendationResponse>> GetRecommendationsAsync(string userId, int take = 20);
}
