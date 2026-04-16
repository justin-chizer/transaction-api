using System.Text.Json.Serialization;
namespace TransactionApi.Models;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum TransactionType
{
    Credit,
    Debit
}

public class Transaction
{
    public Guid Id { get; set; }
    public Guid AccountId { get; set; }
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public decimal BalanceBefore { get; set; }
    public decimal BalanceAfter { get; set; }
    public DateTime CreatedAt { get; set; }

    [JsonIgnore]
    public Account Account { get; set; } = null!;
}