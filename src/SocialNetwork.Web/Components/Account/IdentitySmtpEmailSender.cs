using System.Net;
using System.Net.Mail;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.UI.Services;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.Web.Components.Account;

internal sealed class IdentitySmtpEmailSender(
    IdentityLinkStore linkStore,
    IdentityEmailOptions options,
    ILogger<IdentitySmtpEmailSender> logger) : IEmailSender<ApplicationUser>
{
    public bool IsConfigured => options.IsConfigured || options.UsePickupDirectory;

    public async Task SendConfirmationLinkAsync(ApplicationUser user, string email, string confirmationLink)
    {
        var localLink = WebUtility.HtmlDecode(confirmationLink);
        linkStore.SaveConfirmationLink(email, localLink);

        var body = $"""
            <p>Xin chào {WebUtility.HtmlEncode(user.DisplayName)},</p>
            <p>Vui lòng xác nhận tài khoản Mini Social bằng liên kết dưới đây:</p>
            <p><a href="{confirmationLink}">Xác nhận email</a></p>
            <p>Nếu bạn không tạo tài khoản này, bạn có thể bỏ qua email.</p>
            """;

        await SendEmailAsync(email, "Mini Social - Xác nhận email", body, localLink, "confirmation");
    }

    public async Task SendPasswordResetLinkAsync(ApplicationUser user, string email, string resetLink)
    {
        var localLink = WebUtility.HtmlDecode(resetLink);
        linkStore.SavePasswordResetLink(email, localLink);

        var body = $"""
            <p>Xin chào {WebUtility.HtmlEncode(user.DisplayName)},</p>
            <p>Bạn vừa yêu cầu đặt lại mật khẩu cho tài khoản Mini Social.</p>
            <p><a href="{resetLink}">Đặt lại mật khẩu</a></p>
            <p>Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email.</p>
            """;

        await SendEmailAsync(email, "Mini Social - Đặt lại mật khẩu", body, localLink, "password reset");
    }

    public async Task SendPasswordResetCodeAsync(ApplicationUser user, string email, string resetCode)
    {
        var body = $"""
            <p>Xin chào {WebUtility.HtmlEncode(user.DisplayName)},</p>
            <p>Mã đặt lại mật khẩu của bạn là:</p>
            <p><strong>{WebUtility.HtmlEncode(resetCode)}</strong></p>
            """;

        await SendEmailAsync(email, "Mini Social - Mã đặt lại mật khẩu", body, null, "password reset code");
    }

    private async Task SendEmailAsync(string email, string subject, string htmlBody, string? fallbackLink, string purpose)
    {
        if (!IsConfigured)
        {
            logger.LogWarning(
                "SMTP mail sender is not configured. Skipping {Purpose} email for {Email}. Local link: {Link}",
                purpose,
                email,
                fallbackLink ?? "(none)");
            return;
        }

        using var message = new MailMessage
        {
            From = new MailAddress(options.FromEmail ?? "noreply@localhost", options.FromName),
            Subject = subject,
            Body = htmlBody,
            IsBodyHtml = true
        };
        message.To.Add(email);

        using var client = CreateClient();
        await client.SendMailAsync(message);

        logger.LogInformation("Sent {Purpose} email to {Email}.", purpose, email);
    }

    private SmtpClient CreateClient()
    {
        if (options.UsePickupDirectory)
        {
            Directory.CreateDirectory(options.PickupDirectory!);
            return new SmtpClient
            {
                DeliveryMethod = SmtpDeliveryMethod.SpecifiedPickupDirectory,
                PickupDirectoryLocation = options.PickupDirectory
            };
        }

        var client = new SmtpClient(options.Host!, options.Port)
        {
            DeliveryMethod = SmtpDeliveryMethod.Network,
            EnableSsl = options.EnableSsl,
            UseDefaultCredentials = options.UseDefaultCredentials
        };

        if (!options.UseDefaultCredentials)
        {
            client.Credentials = new NetworkCredential(options.UserName, options.Password);
        }

        return client;
    }
}
