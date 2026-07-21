using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.DTOs.Friend;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Domain.Enums;

namespace MiniSocialNetwork.Application.Services;

public sealed class FriendService : IFriendService
{
    private readonly IFriendRepository _repo;
    private readonly UserManager<AppUser> _userManager;

    public FriendService(IFriendRepository repo, UserManager<AppUser> userManager)
    {
        _repo = repo;
        _userManager = userManager;
    }

    public async Task<Guid> SendRequestAsync(string requesterId, string addresseeId)
    {
        if (requesterId == addresseeId) throw new ArgumentException("Cannot send friend request to yourself");

        var requester = await _userManager.FindByIdAsync(requesterId);
        var addressee = await _userManager.FindByIdAsync(addresseeId);
        if (requester == null || requester.IsDeleted) throw new KeyNotFoundException("Requester not found");
        if (addressee == null || addressee.IsDeleted) throw new KeyNotFoundException("Addressee not found");

        // if already friends
        var between = await _repo.GetBetweenAnyDirectionAsync(requesterId, addresseeId);
        var accepted = between.FirstOrDefault(x => x.Status == FriendRequestStatus.Accepted);
        if (accepted != null) throw new InvalidOperationException("Already friends");

        var pending = between.FirstOrDefault(x => x.Status == FriendRequestStatus.Pending);
        if (pending != null) throw new InvalidOperationException("Friend request already pending");

        // check last declined from addressee to requester (or requester to addressee)
        var latestFromRequester = between.OrderByDescending(x => x.CreatedDate).FirstOrDefault();
        if (latestFromRequester != null && latestFromRequester.Status == FriendRequestStatus.Declined)
        {
            var since = DateTime.UtcNow - latestFromRequester.CreatedDate;
            // if last was declined within 7 days, block
            if (since.TotalDays < 7)
                throw new InvalidOperationException("You must wait 7 days after a declined request to send another");
        }

        var fr = new FriendRequest
        {
            Id = Guid.NewGuid(),
            RequesterId = requesterId,
            AddresseeId = addresseeId,
            Status = FriendRequestStatus.Pending,
            CreatedDate = DateTime.UtcNow
        };

        await _repo.AddAsync(fr);
        await _repo.SaveChangesAsync();
        return fr.Id;
    }

    public async Task<IReadOnlyCollection<FriendRequestResponse>> GetIncomingRequestsAsync(string userId)
    {
        var list = await _repo.GetIncomingRequestsAsync(userId);
        return list.Select(fr => new FriendRequestResponse
        {
            Id = fr.Id,
            RequesterId = fr.RequesterId,
            RequesterName = fr.Requester.DisplayName,
            RequesterAvatarUrl = fr.Requester.AvatarUrl,
            CreatedDate = fr.CreatedDate
        }).ToArray();
    }

    public async Task RespondRequestAsync(Guid requestId, bool accept, string currentUserId)
    {
        var fr = await _repo.GetByIdAsync(requestId);
        if (fr == null) throw new KeyNotFoundException("Request not found");
        if (fr.AddresseeId != currentUserId) throw new UnauthorizedAccessException("Only addressee can respond");

        if (fr.Status != FriendRequestStatus.Pending) throw new InvalidOperationException("Request already responded");

        fr.Status = accept ? FriendRequestStatus.Accepted : FriendRequestStatus.Declined;
        fr.RespondedDate = DateTime.UtcNow;
        await _repo.SaveChangesAsync();
    }

    public async Task<IReadOnlyCollection<FriendUserResponse>> GetFriendsAsync(string userId)
    {
        var friends = await _repo.GetFriendsAsync(userId);
        return friends.Select(u => new FriendUserResponse
        {
            Id = u.Id,
            DisplayName = u.DisplayName,
            AvatarUrl = u.AvatarUrl,
            RelationshipStatus = 1
        }).ToArray();
    }

    public async Task<IReadOnlyCollection<FriendUserResponse>> SearchUsersAsync(string userId, string? keyword)
    {
        var query = _userManager.Users.Where(u => !u.IsDeleted && u.Id != userId);

        if (!string.IsNullOrWhiteSpace(keyword))
        {
            var kw = keyword.Trim();
            // allow search by id or display name
            query = query.Where(u => u.DisplayName.Contains(kw) || u.Id == kw);
        }

        var users = await query.OrderBy(u => u.DisplayName).Take(50).ToListAsync();

        // fetch relationships for these users in bulk
        var userIds = users.Select(u => u.Id).ToArray();
        var relations = await _repo.GetBetweenAnyDirectionAsync(userId, string.Empty); // fallback, we'll use per-user check.

        // For simplicity, check per user
        var results = new List<FriendUserResponse>(users.Count);
        foreach (var u in users)
        {
            var between = await _repo.GetBetweenAnyDirectionAsync(userId, u.Id);
            var latest = between.OrderByDescending(x => x.CreatedDate).FirstOrDefault();
            var status = 0;
            if (latest != null)
            {
                if (latest.Status == FriendRequestStatus.Accepted) status = 1;
                else if (latest.Status == FriendRequestStatus.Pending)
                {
                    status = latest.RequesterId == userId ? 2 : 3; // outgoing or incoming
                }
                else if (latest.Status == FriendRequestStatus.Declined)
                {
                    if ((DateTime.UtcNow - latest.CreatedDate).TotalDays < 7) status = 4; // recently declined
                    else status = 0;
                }
            }

            results.Add(new FriendUserResponse
            {
                Id = u.Id,
                DisplayName = u.DisplayName,
                AvatarUrl = u.AvatarUrl,
                RelationshipStatus = status
            });
        }

        return results;
    }

    // NEW: remove friend
    public async Task RemoveFriendAsync(string currentUserId, string friendId)
    {
        if (currentUserId == friendId) throw new ArgumentException("Cannot remove yourself");

        var between = await _repo.GetBetweenAnyDirectionAsync(currentUserId, friendId);
        var accepted = between.FirstOrDefault(x => x.Status == FriendRequestStatus.Accepted);
        if (accepted == null) throw new KeyNotFoundException("Friend relationship not found");

        await _repo.RemoveFriendshipAsync(currentUserId, friendId);
        await _repo.SaveChangesAsync();
    }
}
