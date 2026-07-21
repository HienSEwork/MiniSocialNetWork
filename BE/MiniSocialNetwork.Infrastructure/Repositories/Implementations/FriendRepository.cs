using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

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
            .Where(fr => fr.Status == Domain.Enums.FriendRequestStatus.Pending &&
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
            .Where(fr => fr.AddresseeId == userId && fr.Status == Domain.Enums.FriendRequestStatus.Pending)
            .Include(fr => fr.Requester)
            .OrderByDescending(fr => fr.CreatedDate)
            .ToListAsync();
    }

    public async Task<List<AppUser>> GetFriendsAsync(string userId, int take = 200)
    {
        var accepted = _context.FriendRequests
            .Where(fr => fr.Status == Domain.Enums.FriendRequestStatus.Accepted &&
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
            .Where(fr => fr.Status == Domain.Enums.FriendRequestStatus.Accepted &&
                         ((fr.RequesterId == userA && fr.AddresseeId == userB) ||
                          (fr.RequesterId == userB && fr.AddresseeId == userA)))
            .ToListAsync();

        if (accepted.Any())
            _context.FriendRequests.RemoveRange(accepted);
    }
}
