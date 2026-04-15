using System.ComponentModel.DataAnnotations;

namespace TransactionApi.Models;

public class TransactionRequest
{
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Amount { get; set; }

    [Required]
    [MaxLength(200)]
    public string Description { get; set; } = string.Empty;
}