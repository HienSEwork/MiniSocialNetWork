using System.Text.RegularExpressions;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.Application.Services;

public sealed partial class TfIdfContentFilter : IContentFilter
{
    private static readonly string[] UnsafeSamples =
    {
        "đe dọa bạo lực làm hại người khác",
        "quấy rối xúc phạm chửi bới người khác",
        "lừa đảo chiếm đoạt tiền thông tin tài khoản",
        "spam quảng cáo cờ bạc cá cược trái phép",
        "threaten violence harm another person",
        "harassment abuse scam illegal gambling spam"
    };

    public bool IsAllowed(string content)
    {
        if (string.IsNullOrWhiteSpace(content)) return true;
        var documents = UnsafeSamples.Append(content).Select(Tokenize).ToArray();
        var vocabulary = documents.SelectMany(tokens => tokens).Distinct().ToArray();
        var inputVector = Vector(documents[^1], documents, vocabulary);
        return documents.Take(documents.Length - 1)
            .Select(tokens => Cosine(inputVector, Vector(tokens, documents, vocabulary)))
            .All(similarity => similarity < 0.62);
    }

    private static string[] Tokenize(string value) => WordPattern()
        .Matches(value.ToLowerInvariant())
        .Select(match => match.Value)
        .Where(token => token.Length > 1)
        .ToArray();

    private static double[] Vector(string[] tokens, string[][] documents, string[] vocabulary)
    {
        var tokenCount = Math.Max(1, tokens.Length);
        return vocabulary.Select(term =>
        {
            var termFrequency = tokens.Count(token => token == term) / (double)tokenCount;
            var documentFrequency = documents.Count(document => document.Contains(term));
            var inverseDocumentFrequency = Math.Log((documents.Length + 1d) / (documentFrequency + 1d)) + 1d;
            return termFrequency * inverseDocumentFrequency;
        }).ToArray();
    }

    private static double Cosine(double[] left, double[] right)
    {
        var dot = left.Zip(right, (a, b) => a * b).Sum();
        var leftLength = Math.Sqrt(left.Sum(value => value * value));
        var rightLength = Math.Sqrt(right.Sum(value => value * value));
        return leftLength == 0 || rightLength == 0 ? 0 : dot / (leftLength * rightLength);
    }

    [GeneratedRegex(@"[\p{L}\p{N}]+")]
    private static partial Regex WordPattern();
}
