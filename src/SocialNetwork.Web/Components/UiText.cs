using System.Globalization;

namespace SocialNetwork.Web.Components;

public static class UiText
{
    public static bool IsEnglish =>
        string.Equals(CultureInfo.CurrentUICulture.TwoLetterISOLanguageName, "en", StringComparison.OrdinalIgnoreCase);

    public static string T(string vietnamese, string english) => IsEnglish ? english : vietnamese;
}
