using Microsoft.AspNetCore.Identity;
using System.Security.Authentication;
using MiniSocialNetwork.Application.DTOs.Auth;
using MiniSocialNetwork.Application.Exceptions;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public sealed class AuthService : IAuthService
{
    private readonly UserManager<AppUser> _userManager;
    private readonly ITokenService _tokenService;

    public AuthService(UserManager<AppUser> userManager, ITokenService tokenService)
    {
        _userManager = userManager;
        _tokenService = tokenService;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(email) || !email.Contains('@'))
            throw new ArgumentException("Email is invalid");
        if (request.Password.Length < 6)
            throw new ArgumentException("Password must contain at least 6 characters");
        if (request.DisplayName.Trim().Length < 2)
            throw new ArgumentException("Display name must contain at least 2 characters");
        if (await _userManager.FindByEmailAsync(email) != null)
            throw new ConflictException("Email is already registered");

        var user = new AppUser
        {
            UserName = email,
            Email = email,
            DisplayName = request.DisplayName.Trim(),
            CreatedDate = DateTime.UtcNow,
            IsDeleted = false
        };
        var result = await _userManager.CreateAsync(user, request.Password);
        EnsureSucceeded(result);
        result = await _userManager.AddToRoleAsync(user, "User");
        EnsureSucceeded(result);
        return await BuildAuthResponseAsync(user);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email.Trim());
        // Check null first, then IsDeleted and password
        if (user == null || user.IsDeleted || !await _userManager.CheckPasswordAsync(user, request.Password))
            throw new AuthenticationException("Email or password is incorrect");

        return await BuildAuthResponseAsync(user);
    }

    public async Task<UserProfileResponse> GetProfileAsync(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null || user.IsDeleted) throw new KeyNotFoundException("User not found");
        return await MapProfileAsync(user);
    }

    public async Task<UserProfileResponse> UpdateProfileAsync(string userId, UpdateProfileRequest request)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null || user.IsDeleted) throw new KeyNotFoundException("User not found");
        if (request.DisplayName.Trim().Length < 2)
            throw new ArgumentException("Display name must contain at least 2 characters");

        user.DisplayName = request.DisplayName.Trim();
        user.Bio = string.IsNullOrWhiteSpace(request.Bio) ? null : request.Bio.Trim();
        user.AvatarUrl = string.IsNullOrWhiteSpace(request.AvatarUrl) ? null : request.AvatarUrl.Trim();
        EnsureSucceeded(await _userManager.UpdateAsync(user));
        return await MapProfileAsync(user);
    }

    public async Task<ForgotPasswordResponse> ForgotPasswordAsync(ForgotPasswordRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email.Trim());
        if (user == null || user.IsDeleted)
            return new ForgotPasswordResponse { Message = "If the account exists, a reset token has been generated" };

        return new ForgotPasswordResponse
        {
            Message = "Password reset token generated",
            ResetToken = await _userManager.GeneratePasswordResetTokenAsync(user)
        };
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email.Trim());
        if (user == null || user.IsDeleted) throw new ArgumentException("Invalid reset request");
        EnsureSucceeded(await _userManager.ResetPasswordAsync(user, request.Token, request.NewPassword));
    }

    private async Task<AuthResponse> BuildAuthResponseAsync(AppUser user)
    {
        var token = await _tokenService.CreateAsync(user);
        return new AuthResponse
        {
            Token = token.Token,
            ExpiresAt = token.ExpiresAt,
            User = await MapProfileAsync(user)
        };
    }

    private async Task<UserProfileResponse> MapProfileAsync(AppUser user) => new()
    {
        Id = user.Id,
        Email = user.Email ?? string.Empty,
        DisplayName = user.DisplayName,
        AvatarUrl = user.AvatarUrl,
        Bio = user.Bio,
        CreatedDate = user.CreatedDate,
        Roles = (await _userManager.GetRolesAsync(user)).ToArray()
    };

    private static void EnsureSucceeded(IdentityResult result)
    {
        if (!result.Succeeded)
            throw new ArgumentException(string.Join("; ", result.Errors.Select(error => error.Description)));
    }
}
