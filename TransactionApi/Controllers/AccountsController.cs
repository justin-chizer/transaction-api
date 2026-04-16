using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TransactionApi.Models;
using TransactionApi.Data;

namespace TransactionApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class AccountsController : ControllerBase
{
    private readonly BankingDbContext _context;

    public AccountsController(BankingDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<Account>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<Account>>> GetAccounts()
    {
        return await _context.Accounts.AsNoTracking().ToListAsync();
    }

    [HttpGet("{id}")]
    [ProducesResponseType(typeof(Account), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<Account>> GetAccount(Guid id)
    {
        var account = await _context.Accounts.AsNoTracking()
            .FirstOrDefaultAsync(a => a.Id == id);

        if (account == null)
        {
            return NotFound();
        }

        return account;
    }

    [HttpPost]
    [ProducesResponseType(typeof(Account), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<Account>> CreateAccount(Account account)
    {
        account.Id = Guid.NewGuid();
        account.CreatedAt = DateTime.UtcNow;
        account.Balance = 0;

        _context.Accounts.Add(account);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAccount), new { id = account.Id }, account);
    }
}