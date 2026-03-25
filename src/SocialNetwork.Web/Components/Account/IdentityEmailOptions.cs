namespace SocialNetwork.Web.Components.Account;

internal sealed class IdentityEmailOptions
{
    public string? Host { get; init; }

    public int Port { get; init; } = 587;

    public string? UserName { get; init; }

    public string? Password { get; init; }

    public string? FromEmail { get; init; }

    public string FromName { get; init; } = "Mini Social";

    public bool EnableSsl { get; init; } = true;

    public bool UseDefaultCredentials { get; init; }

    public string? PickupDirectory { get; init; }

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(Host) &&
        !string.IsNullOrWhiteSpace(FromEmail) &&
        (UseDefaultCredentials || !string.IsNullOrWhiteSpace(UserName));

    public bool UsePickupDirectory => !string.IsNullOrWhiteSpace(PickupDirectory);
}
