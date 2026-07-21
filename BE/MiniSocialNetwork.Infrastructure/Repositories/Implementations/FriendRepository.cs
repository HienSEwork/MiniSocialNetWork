using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;
using MiniSocialNetwork.Application.DTOs.Friend;
using MiniSocialNetwork.Domain.Enums;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public sealed class FriendRepository : IFriendRepository
{
    private readonly AppDbContext _context;
    public FriendRepository(AppDbContext context) => _context = context;

    public Task<FriendRequest?> GetByIdAsync(Guid id)
        => _context.FriendRequests
            .Include(fr => fr.Requester)
            .Include(fr => fr.Addressee)
            .FirstOrDefaultAsync(fr => fr.Id == id);

    public Task<FriendRequest?> GetPendingBetweenAsync(string userA, string userB)
        => _context.FriendRequests
            .Where(fr => fr.Status == FriendRequestStatus.Pending &&
                         ((fr.RequesterId == userA && fr.AddresseeId == userB) ||
                          (fr.RequesterId == userB && fr.AddresseeId == userA)))
            .FirstOrDefaultAsync();

    public Task<FriendRequest?> GetLatestBetweenAsync(string requesterId, string addresseeId)
        => _context.FriendRequests
            .Where(fr => fr.RequesterId == requesterId && fr.AddresseeId == addresseeId)
            .OrderByDescending(fr => fr.CreatedDate)
            .FirstOrDefaultAsync();

    public Task AddAsync(FriendRequest request) => _context.FriendRequests.AddAsync(request).AsTask();
    public Task SaveChangesAsync() => _context.SaveChangesAsync();

    public async Task<List<FriendRequest>> GetIncomingRequestsAsync(string userId)
    {
        return await _context.FriendRequests
            .Where(fr => fr.AddresseeId == userId && fr.Status == FriendRequestStatus.Pending)
            .Include(fr => fr.Requester)
            .OrderByDescending(fr => fr.CreatedDate)
            .ToListAsync();
    }

    public async Task<List<AppUser>> GetFriendsAsync(string userId, int take = 200)
    {
        var accepted = _context.FriendRequests
            .Where(fr => fr.Status == FriendRequestStatus.Accepted &&
                         (fr.RequesterId == userId || fr.AddresseeId == userId))
            .Include(fr => fr.Requester)
            .Include(fr => fr.Addressee);

        var users = await accepted
            .Select(fr => fr.RequesterId == userId ? fr.Addressee : fr.Requester)
            .Distinct()
            .Take(Math.Clamp(take, 1, 2000))
            .ToListAsync();

        return users;
    }

    public Task<List<FriendRequest>> GetBetweenAnyDirectionAsync(string userA, string userB)
        => _context.FriendRequests
            .Where(fr => (fr.RequesterId == userA && fr.AddresseeId == userB) ||
                         (fr.RequesterId == userB && fr.AddresseeId == userA))
            .OrderByDescending(fr => fr.CreatedDate)
            .ToListAsync();

    public async Task RemoveFriendshipAsync(string userA, string userB)
    {
        var accepted = await _context.FriendRequests
            .Where(fr => fr.Status == FriendRequestStatus.Accepted &&
                         ((fr.RequesterId == userA && fr.AddresseeId == userB) ||
                          (fr.RequesterId == userB && fr.AddresseeId == userA)))
            .ToListAsync();

        if (accepted.Any())
            _context.FriendRequests.RemoveRange(accepted);
    }

    // NEW: Recommendation logic
    public async Task<List<RecommendationResponse>> GetRecommendationsAsync(string userId, int take = 20)
    {
        // 1) get user's current friends
        var userFriends = await _context.FriendRequests
            .Where(fr => fr.Status == FriendRequestStatus.Accepted &&
                         (fr.RequesterId == userId || fr.AddresseeId == userId))
            .Select(fr => fr.RequesterId == userId ? fr.AddresseeId : fr.RequesterId)
            .Distinct()
            .ToListAsync();

        // 2) get groups user belongs to
        var userGroupIds = await _context.GroupMembers
            .Where(gm => gm.UserId == userId)
            .Select(gm => gm.GroupId)
            .Distinct()
            .ToListAsync();

        // 3) candidates from friends-of-friends (mutual) and from shared groups
        var mutualCandidates = new List<string>();
        if (userFriends.Any())
        {
            var acceptedEdges = await _context.FriendRequests
                .Where(fr => fr.Status == FriendRequestStatus.Accepted &&
                             (userFriends.Contains(fr.RequesterId) || userFriends.Contains(fr.AddresseeId)))
                .Select(fr => new { fr.RequesterId, fr.AddresseeId })
                .ToListAsync();

            foreach (var e in acceptedEdges)
            {
                // for each edge, find the node that is not one of the original user's friends => candidate
                if (userFriends.Contains(e.RequesterId) && e.AddresseeId != userId && !userFriends.Contains(e.AddresseeId))
                    mutualCandidates.Add(e.AddresseeId);
                if (userFriends.Contains(e.AddresseeId) && e.RequesterId != userId && !userFriends.Contains(e.RequesterId))
                    mutualCandidates.Add(e.RequesterId);
            }
        }

        var groupCandidates = new List<string>();
        if (userGroupIds.Any())
        {
            groupCandidates = await _context.GroupMembers
                .Where(gm => userGroupIds.Contains(gm.GroupId) && gm.UserId != userId)
                .Select(gm => gm.UserId)
                .Distinct()
                .ToListAsync();
        }

        // union of candidates (excluding self and existing friends)
        var allCandidates = mutualCandidates.Concat(groupCandidates)
            .Where(id => id != userId && !userFriends.Contains(id))
            .Distinct()
            .ToList();

        if (!allCandidates.Any())
            return new List<RecommendationResponse>();

        // prefetch user info
        var users = await _context.Users
            .Where(u => allCandidates.Contains(u.Id) && !u.IsDeleted)
            .ToListAsync();

        // compute mutual friend counts
        var mutualCounts = new Dictionary<string,int>(StringComparer.Ordinal);
        if (userFriends.Any())
        {
            var fofEdges = await _context.FriendRequests
                .Where(fr => fr.Status == FriendRequestStatus.Accepted &&
                             (userFriends.Contains(fr.RequesterId) || userFriends.Contains(fr.AddresseeId)))
                .Select(fr => new { fr.RequesterId, fr.AddresseeId })
                .ToListAsync();

            foreach (var u in users)
            {
                int count = 0;
                // count how many of user's friends are also friends with u
                foreach (var f in userFriends)
                {
                    // check if there's an accepted edge between f and u
                    if (fofEdges.Any(e => (e.RequesterId == f && e.AddresseeId == u.Id) || (e.RequesterId == u.Id && e.AddresseeId == f)))
                        count++;
                }
                mutualCounts[u.Id] = count;
            }
        }

        // compute shared group counts
        var sharedGroupCounts = new Dictionary<string,int>(StringComparer.Ordinal);
        if (userGroupIds.Any())
        {
            var groupPairs = await _context.GroupMembers
                .Where(gm => allCandidates.Contains(gm.UserId) && userGroupIds.Contains(gm.GroupId))
                .GroupBy(gm => gm.UserId)
                .Select(g => new { UserId = g.Key, Count = g.Select(x => x.GroupId).Distinct().Count() })
                .ToListAsync();

            foreach (var gp in groupPairs)
                sharedGroupCounts[gp.UserId] = gp.Count;
        }

        // determine relationship status per candidate (based on latest friendrequest between user and candidate)
        var relations = await _context.FriendRequests
            .Where(fr => (fr.RequesterId == userId && allCandidates.Contains(fr.AddresseeId)) ||
                         (fr.AddresseeId == userId && allCandidates.Contains(fr.RequesterId)))
            .GroupBy(fr => (fr.RequesterId == userId ? fr.AddresseeId : fr.RequesterId))
            .Select(g => new { CandidateId = g.Key, Latest = g.OrderByDescending(x => x.CreatedDate).FirstOrDefault() })
            .ToListAsync();

        var relationMap = new Dictionary<string, FriendRequest?>(StringComparer.Ordinal);
        foreach (var r in relations)
            relationMap[r.CandidateId] = r.Latest;

        // prepare result with scoring: mutual * 10 + sharedGroups
        var results = users.Select(u =>
        {
            relationMap.TryGetValue(u.Id, out var latest);
            int status = 0;
            if (latest != null)
            {
                if (latest.Status == FriendRequestStatus.Accepted) status = 1;
                else if (latest.Status == FriendRequestStatus.Pending)
                    status = latest.RequesterId == userId ? 2 : 3;
                else if (latest.Status == FriendRequestStatus.Declined)
                {
                    if ((DateTime.UtcNow - latest.CreatedDate).TotalDays < 7) status = 4;
                    else status = 0;
                }
            }

            mutualCounts.TryGetValue(u.Id, out var mf);
            sharedGroupCounts.TryGetValue(u.Id, out var sg);

            return new
            {
                User = u,
                Mutual = mf,
                Shared = sg,
                Score = (mf * 10) + sg,
                Status = status
            };
        })
        .OrderByDescending(x => x.Score)
        .ThenBy(x => x.User.DisplayName)
        .Take(Math.Clamp(take, 1, 200))
        .Select(x => new RecommendationResponse
        {
            Id = x.User.Id,
            DisplayName = x.User.DisplayName,
            AvatarUrl = x.User.AvatarUrl,
            MutualFriends = x.Mutual,
            SharedGroups = x.Shared,
            RelationshipStatus = x.Status
        })
        .ToList();

        return results;
    }
}
