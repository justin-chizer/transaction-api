using Microsoft.EntityFrameworkCore;
using TransactionApi.Models;

namespace TransactionApi.Data;

public class BankingDbContext : DbContext
{
    public BankingDbContext(DbContextOptions<BankingDbContext> options) : base(options)
    {
    }

    public DbSet<Account> Accounts { get; set; }
    public DbSet<Transaction> Transactions { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Account>(entity =>
        {
            entity.HasKey(a => a.Id);
            entity.Property(a => a.Balance).HasColumnType("decimal(18,2)");
        });
        modelBuilder.Entity<Transaction>(entity =>
        {
            entity.HasKey(t => t.Id);
            entity.Property(t => t.Amount).HasColumnType("decimal(18,2)");
            entity.Property(t => t.BalanceBefore).HasColumnType("decimal(18,2)");
            entity.Property(t => t.BalanceAfter).HasColumnType("decimal(18,2)");
            entity.Property(t => t.Type).HasConversion<string>();
        });
    }
}