// SPDX-License-Identifier: MIT 
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title CarbonToken42
 * @dev Implementation of ERC20 token with type-safe multisig functionality
 * @author ael-yamo
 * @notice This contract was deployed by ael-yamo on 18/03/2025.
 * @dev This contract follows the ERC20 standard and includes additional functionality for carbon credit management.
 */
contract CarbonToken42 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    
    // Multisig related state variables
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;
    
    enum TransactionType { Mint, ChangeRequirement }
    
    struct Transaction {
        TransactionType txType;
        address account;      // Target account for mint/burn
        uint256 amount;      // Amount for mint/burn or new requirement
        bool executed;
    }
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isOwner;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    
    event TransactionSubmitted(uint256 indexed transactionId, TransactionType txType);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event RequirementChanged(uint256 newRequired);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Constructor initializes token metadata and multisig governance
     * @param _owners List of owners for multisig
     * @param _required Number of required confirmations
     */
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 1, "Owners required");
        require(_required > 1 && _required <= _owners.length, "Invalid required number of owners");
        
        _name = "CARBON42";
        _symbol = "C42";
        
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            require(!isOwner[_owners[i]], "Owner not unique");
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        required = _required;
    }
    
    /**
     * @dev Submits a mint transaction to create new tokens
     * @param account Address to receive minted tokens
     * @param carbonTons Amount of carbon credits
     * @return transactionId ID of the created transaction
     */
    function submitMintTransaction(address account, uint256 carbonTons) public returns (uint256) {
        require(isOwner[msg.sender], "Not an owner");
        require(account != address(0), "Invalid account");
        
        uint256 tokens = carbonTons / 2;
        uint256 transactionId = transactionCount;
        
        transactions[transactionId] = Transaction({
            txType: TransactionType.Mint,
            account: account,
            amount: tokens * (10 ** decimals()),
            executed: false
        });
        
        transactionCount += 1;
        emit TransactionSubmitted(transactionId, TransactionType.Mint);
        confirmTransaction(transactionId);
        return transactionId;
    }
    
    /**
     * @dev Submits a governance change transaction to modify required confirmations
     * @param newRequired New number of required confirmations
     */
    function submitRequirementChange(uint256 newRequired) public {
        require(isOwner[msg.sender], "Not an owner");
        require(newRequired > 0 && newRequired <= owners.length, "Invalid required number");
        
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            txType: TransactionType.ChangeRequirement,
            account: address(0),
            amount: newRequired,
            executed: false
        });
        
        transactionCount += 1;
        emit TransactionSubmitted(transactionId, TransactionType.ChangeRequirement);
        confirmTransaction(transactionId);
    }
    
    /**
     * @dev Allows an owner to confirm a pending transaction
     * @param transactionId ID of the transaction to confirm
     */
    function confirmTransaction(uint256 transactionId) public {
        require(isOwner[msg.sender], "Not an owner");
        require(transactions[transactionId].account != address(0) || 
                transactions[transactionId].txType == TransactionType.ChangeRequirement,
                "Transaction does not exist");
        require(!confirmations[transactionId][msg.sender], "Already confirmed");
        
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        
        // executeTransaction(transactionId);
    }

    /**
     * @dev Retrieves all submitted transactions.
     * @return An array containing all transactions stored in the contract.
     */
    function getTransactions() public view returns (Transaction[] memory) {
        Transaction[] memory allTransactions = new Transaction[](transactionCount);
        for (uint256 i = 0; i < transactionCount; i++) {
            allTransactions[i] = transactions[i];
        }
        return allTransactions;
    }

    /**
     * @dev Executes a confirmed transaction if it has received the required approvals.
     * @param transactionId The ID of the transaction to execute.
     */
    function executeTransaction(uint256 transactionId) public {
        require(isConfirmed(transactionId), "Not enough confirmations");
        Transaction storage transaction = transactions[transactionId];
        require(!transaction.executed, "Already executed");
        
        transaction.executed = true;
        
        bool success = false;
        
        if (transaction.txType == TransactionType.Mint) {
            success = executeMint(transaction.account, transaction.amount);
        } else if (transaction.txType == TransactionType.ChangeRequirement) {
            success = executeRequirementChange(transaction.amount);
        }
        
        if (success) {
            emit Execution(transactionId);
        } else {
            transaction.executed = false;
            emit ExecutionFailure(transactionId);
        }
    }
    
    // Internal execution functions
    /**
     * @dev Mints new tokens and assigns them to the specified account.
     * @param account The address receiving the newly minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean indicating whether the operation was successful.
     */
    function executeMint(address account, uint256 amount) internal returns (bool) {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }


    /**
     * @dev Burns tokens from the sender's balance.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public returns (bool) {
        return executeBurn(msg.sender, amount);
    }

    /**
     * @dev Burns a specified amount of tokens from an account, reducing total supply.
     * @param account The address from which tokens will be burned.
     * @param amount The amount of tokens to burn.
     * @return A boolean indicating whether the operation was successful.
     */
    function executeBurn(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "Invalid sender");
        require(_balances[account] >= amount, "Insufficient balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
        return true;
    }

    /**
     * @dev Changes the required number of confirmations for executing transactions.
     * @param newRequired The new required number of confirmations.
     * @return A boolean indicating whether the operation was successful.
     */
    function executeRequirementChange(uint256 newRequired) internal returns (bool) {
        required = newRequired;
        emit RequirementChanged(newRequired);
        return true;
    }

    /**
     * @dev Checks whether a transaction has received the required confirmations.
     * @param transactionId The ID of the transaction to check.
     * @return A boolean indicating whether the transaction is confirmed.
     */
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }
    
    // Standard ERC20 functionality
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(_allowances[from][msg.sender] >= value, "Insufficient allowance");
        _allowances[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Invalid spender");
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Invalid recipient");
        require(_balances[from] >= value, "Insufficient balance");
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }
}