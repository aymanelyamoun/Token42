# CarbonToken42 - ERC20 Token with Multisig Governance

## Events

### Transaction Events
- **TransactionSubmitted(uint256 transactionId, TransactionType txType)**: Emitted when a transaction is proposed.
- **Confirmation(address sender, uint256 transactionId)**: Logs a confirmation.
- **Execution(uint256 transactionId)**: Emitted when a transaction is successfully executed.
- **ExecutionFailure(uint256 transactionId)**: Logs a failed transaction.
- **RequirementChanged(uint256 newRequired)**: Triggered when governance rules change.

### ERC20 Standard Events
- **Transfer(address from, address to, uint256 value)**: Standard ERC20 transfer event.
- **Approval(address owner, address spender, uint256 value)**: Standard ERC20 approval event.
- **Burn(address burner, uint256 value)**: Logs a token burn.

## Functions

### Constructor
```solidity
constructor(address[] memory _owners, uint256 _required)
```
Initializes token metadata and sets up multi-signature governance.

## Multisig Transaction Submission

### Minting
```solidity
function submitMintTransaction(address account, uint256 carbonTons) public returns (uint256)
```
Proposes a mint transaction. (mints 1 carbon token C42 for each 2 carbonTons)

### Change Governance Requirements
```solidity
function submitRequirementChange(uint256 newRequired) public
```
Proposes a change in the number of required confirmations.

## Confirmation and Execution

### Confirm Transaction
```solidity
function confirmTransaction(uint256 transactionId) public
```
Allows an owner to confirm a pending transaction.

### Execute Transaction
```solidity
function executeTransaction(uint256 transactionId) public
```
Executes a confirmed transaction if it meets the required approvals.

## ERC20 Functions

### Standard ERC20 Functions
- **name()**, **symbol()**, **decimals()**, **totalSupply()**, **balanceOf(address owner)**: Standard ERC20 view functions.
- **transfer(address to, uint256 value)**: Transfers tokens.
- **approve(address spender, uint256 value)**: Approves spender for token transfers.
- **transferFrom(address from, address to, uint256 value)**: Executes an approved token transfer.
- **allowance(address owner, address spender)**: Checks an address’s spending allowance.

### Burning
```solidity
function burn(uint256 amount) public returns (bool)
```
burn(destroy tokens) amount from the sender address transaction.