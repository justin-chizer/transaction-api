using System.ComponentModel.DataAnnotations;

namespace TransactionApi.Models;

public class Account
{
    public Guid Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Owner { get; set; } = string.Empty;
    
    [Range(0,double.MaxValue)]
    public decimal Balance { get; set; }
    public DateTime CreatedAt { get; set; }
}