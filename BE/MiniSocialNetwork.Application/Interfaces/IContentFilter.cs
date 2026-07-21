namespace MiniSocialNetwork.Application.Interfaces;

public interface IContentFilter
{
    bool IsAllowed(string content);
}
