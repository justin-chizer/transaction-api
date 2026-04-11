using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TransactionApi.Models;
using TransactionApi.Data;

namespace TransactionApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TransactionsController : ControllerBase
{
    private readonly BankingDbContext _context;

    public TransactionsController(BankingDbContext context)
    {
        _context = context;
    }

    [HttpGet("{accountId}")]
    public async Task<ActionResult<IEnumerable<Transaction>>> GetTransactions(Guid accountId)
    {
        var account = await _context.Accounts.FindAsync(accountId);
        
        if (account == null)
        {
            return NotFound();
        }

        return await _context.Transactions
            .Where(t => t.AccountId == accountId)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();
    }

    [HttpPost("{accountId}/credit")]
    public async Task<ActionResult<Transaction>> Credit(Guid accountId, [FromBody] TransactionRequest request)
    {
        var account = await _context.Accounts.FindAsync(accountId);

        if (account == null)
        {
            return NotFound();
        }

        var transaction = new Transaction
        {
            Id = Guid.NewGuid(),
            AccountId = accountId,
            Type = TransactionType.Credit,
            Amount = request.Amount,
            Description = request.Description,
            BalanceBefore = account.Balance,
            BalanceAfter = account.Balance + request.Amount,
            CreatedAt = DateTime.UtcNow
        };

        account.Balance = transaction.BalanceAfter;
        _context.Transactions.Add(transaction);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetTransactions), new { accountId }, transaction);
    }

    [HttpPost("{accountId}/debit")]
    public async Task<ActionResult<Transaction>> Debit(Guid accountId, [FromBody] TransactionRequest request)
    {
        var account = await _context.Accounts.FindAsync(accountId);

        if (account == null)
        {
            return NotFound();
        }

        if (request.Amount > account.Balance)
        {
            return BadRequest("Insufficient funds.");
        }

        var transaction = new Transaction
        {
            Id = Guid.NewGuid(),
            AccountId = accountId,
            Type = TransactionType.Debit,
            Amount = request.Amount,
            Description = request.Description,
            BalanceBefore = account.Balance,
            BalanceAfter = account.Balance - request.Amount,
            CreatedAt = DateTime.UtcNow
        };

        account.Balance = transaction.BalanceAfter;

        _context.Transactions.Add(transaction);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetTransactions), new { accountId }, transaction);
    }
}