









// SPDX-License-Identifier: MIT 
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title CarbonToken42 hh
 * @dev Implementation of ERC20 token with type-safe multisig functionality
 */


contract CarbonToken42 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    
    // Multisig related state variables
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;
    
    enum TransactionType { Mint, Burn, ChangeRequirement }
    
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
    
    // Multisig submission functions - one for each transaction type
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
    
    function submitBurnTransaction(uint256 amount) public {
        require(isOwner[msg.sender], "Not an owner");
        
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            txType: TransactionType.Burn,
            account: msg.sender,
            amount: amount,
            executed: false
        });
        
        transactionCount += 1;
        emit TransactionSubmitted(transactionId, TransactionType.Burn);
        confirmTransaction(transactionId);
    }
    
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
    
    // Confirmation and execution
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

    function getTransactions() public view returns (Transaction[] memory) {
        Transaction[] memory allTransactions = new Transaction[](transactionCount);
        for (uint256 i = 0; i < transactionCount; i++) {
            allTransactions[i] = transactions[i];
        }
        return allTransactions;
    }

    function executeTransaction(uint256 transactionId) public {
        require(isConfirmed(transactionId), "Not enough confirmations");
        Transaction storage transaction = transactions[transactionId];
        require(!transaction.executed, "Already executed");
        
        transaction.executed = true;
        
        bool success = false;
        
        if (transaction.txType == TransactionType.Mint) {
            success = executeMint(transaction.account, transaction.amount);
        } else if (transaction.txType == TransactionType.Burn) {
            success = executeBurn(transaction.account, transaction.amount);
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
    function executeMint(address account, uint256 amount) internal returns (bool) {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }
    
    function executeBurn(address account, uint256 amount) internal returns (bool) {
        require(_balances[account] >= amount, "Insufficient balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
        return true;
    }
    
    function executeRequirementChange(uint256 newRequired) internal returns (bool) {
        required = newRequired;
        emit RequirementChanged(newRequired);
        return true;
    }
    
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

// pragma solidity >=0.8.2 <0.9.0;

// /**
//  * @title CarbonToken42
//  * @dev Implementation of ERC20 token with multisig functionality for minting
//  */
// contract CarbonToken42 {
//     string private _name;
//     string private _symbol;
//     uint256 private _totalSupply;
    
//     // Multisig related state variables
//     address[] public owners;
//     uint256 public required;
//     uint256 public transactionCount;
    
//     mapping(address => uint256) private _balances;
//     mapping(address => mapping(address => uint256)) private _allowances;
//     mapping(address => bool) public isOwner;
//     mapping(uint256 => Transaction) public transactions;
//     mapping(uint256 => mapping(address => bool)) public confirmations;
    
//     struct Transaction {
//         address destination;
//         uint256 value;
//         bool executed;
//         bytes data;
//     }
    
//     event Submission(uint256 indexed transactionId);
//     event Confirmation(address indexed sender, uint256 indexed transactionId);
//     event Execution(uint256 indexed transactionId);
//     event ExecutionFailure(uint256 indexed transactionId);
//     event Deposit(address indexed sender, uint256 value);
//     event Transfer(address indexed from, address indexed to, uint256 value);
//     event Approval(address indexed owner, address indexed spender, uint256 value);
//     event Burn(address indexed burner, uint256 value);

//     constructor(address[] memory _owners, uint256 _required) {
//         require(_owners.length > 0, "Owners required");
//         require(_required > 0 && _required <= _owners.length, "Invalid required number of owners");
        
//         _name = "CARBON42";
//         _symbol = "C42";
        
//         for (uint256 i = 0; i < _owners.length; i++) {
//             require(_owners[i] != address(0), "Invalid owner");
//             require(!isOwner[_owners[i]], "Owner not unique");
//             isOwner[_owners[i]] = true;
//             owners.push(_owners[i]);
//         }
//         required = _required;
//     }
    
//     // Multisig functionality
//     function submitTransaction(
//         address _destination,
//         uint256 _value,
//         bytes memory _data
//     ) public returns (uint256 transactionId) {
//         require(isOwner[msg.sender], "Not an owner");
//         transactionId = transactionCount;
//         transactions[transactionId] = Transaction({
//             destination: _destination,
//             value: _value,
//             executed: false,
//             data: _data
//         });
//         transactionCount += 1;
//         emit Submission(transactionId);
//         confirmTransaction(transactionId);
//     }
    
//     function confirmTransaction(uint256 transactionId) public {
//         require(isOwner[msg.sender], "Not an owner");
//         require(transactions[transactionId].destination != address(0), "Transaction does not exist");
//         require(!confirmations[transactionId][msg.sender], "Transaction already confirmed");
        
//         confirmations[transactionId][msg.sender] = true;
//         emit Confirmation(msg.sender, transactionId);
//         executeTransaction(transactionId);
//     }
    
//     function executeTransaction(uint256 transactionId) public {
//         require(transactions[transactionId].destination != address(0), "Transaction does not exist");
//         require(!transactions[transactionId].executed, "Transaction already executed");
        
//         if (isConfirmed(transactionId)) {
//             Transaction storage transaction = transactions[transactionId];
//             transaction.executed = true;
            
//             // Execute the transaction
//             (bool success, ) = transaction.destination.call{value: transaction.value}(
//                 transaction.data
//             );
            
//             if (success)
//                 emit Execution(transactionId);
//             else {
//                 emit ExecutionFailure(transactionId);
//                 transaction.executed = false;
//             }
//         }
//     }
    
//     function isConfirmed(uint256 transactionId) public view returns (bool) {
//         uint256 count = 0;
//         for (uint256 i = 0; i < owners.length; i++) {
//             if (confirmations[transactionId][owners[i]])
//                 count += 1;
//             if (count == required)
//                 return true;
//         }
//         return false;
//     }
    
//     // Standard ERC20 functionality
//     function name() public view returns (string memory) {
//         return _name;
//     }

//     function symbol() public view returns (string memory) {
//         return _symbol;
//     }

//     function decimals() public pure returns (uint8) {
//         return 18;
//     }

//     function totalSupply() public view returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address owner) public view returns (uint256) {
//         return _balances[owner];
//     }

//     function transfer(address to, uint256 value) public returns (bool) {
//         _transfer(msg.sender, to, value);
//         return true;
//     }

//     function transferFrom(address from, address to, uint256 value) public returns (bool) {
//         require(_allowances[from][msg.sender] >= value, "Insufficient allowance");
//         _allowances[from][msg.sender] -= value;
//         _transfer(from, to, value);
//         return true;
//     }

//     function approve(address spender, uint256 value) public returns (bool) {
//         require(spender != address(0), "Invalid spender");
//         _allowances[msg.sender][spender] = value;
//         emit Approval(msg.sender, spender, value);
//         return true;
//     }

//     function allowance(address owner, address spender) public view returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     // Mint function that requires multisig approval
//     function mintCarbonTokens(address account, uint256 carbonTons) public returns (bool) {
//         require(isOwner[msg.sender], "Not an owner");
//         uint256 tokens = carbonTons / 2;
//         bytes memory data = abi.encodeWithSignature("_mint(address,uint256)", account, tokens * (10 ** decimals()));
//         submitTransaction(address(this), 0, data);
//         return true;
//     }

//     function burn(uint256 value) public returns (bool) {
//         require(_balances[msg.sender] >= value, "Insufficient balance");
//         _balances[msg.sender] -= value;
//         _totalSupply -= value;
//         emit Burn(msg.sender, value);
//         emit Transfer(msg.sender, address(0), value);
//         return true;
//     }

//     function _transfer(address from, address to, uint256 value) internal {
//         require(to != address(0), "Invalid recipient");
//         require(_balances[from] >= value, "Insufficient balance");
//         _balances[from] -= value;
//         _balances[to] += value;
//         emit Transfer(from, to, value);
//     }

//     function _mint(address account, uint256 amount) internal {
//         require(account != address(0), "Invalid recipient");
//         _totalSupply += amount;
//         _balances[account] += amount;
//         emit Transfer(address(0), account, amount);
//     }
    
//     receive() external payable {
//         if (msg.value > 0)
//             emit Deposit(msg.sender, msg.value);
//     }
// }

// pragma solidity >=0.8.2 <0.9.0;

// /**
//  * @title CarbonToken42
//  * @dev Implementation of a basic ERC20 token with additional validator functionality
//  */
// contract CarbonToken42 {
//     string private _name;
//     string private _symbol;
//     uint256 private _totalSupply;
//     address private _contratOwner;

//     mapping(address => uint256) private _balances;
//     mapping(address => mapping(address => uint256)) private _allowances;
//     mapping(address => bool) private _validators;

//     event Transfer(address indexed _from, address indexed _to, uint256 _value);
//     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
//     event ValidatorAdded(address indexed validator);
//     event ValidatorRemoved(address indexed validator);
//     event Burn(address indexed burner, uint256 value);

//     constructor() {
//     // constructor(string memory name_, string memory symbol_, uint256 initialSupply) {
//         _name = "CARBON42";
//         _symbol = "C42";
//         _contratOwner = payable(msg.sender);
//         // _mint(_contratOwner, initialSupply * (10 ** decimals()));
//     }

//     modifier onlyOwner() {
//         require(msg.sender == _contratOwner, "Only owner can call this function.");
//         _;
//     }

//     modifier onlyValidator() {
//         require(_validators[msg.sender], "Only validators can execute this function");
//         _;
//     }

//     function name() public view returns (string memory) {
//         return _name;
//     }

//     function symbol() public view returns (string memory) {
//         return _symbol;
//     }

//     function decimals() public pure returns (uint8) {
//         return 18;
//     }

//     function totalSupply() public view returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address _owner) public view returns (uint256) {
//         return _balances[_owner];
//     }

//     function transfer(address _to, uint256 _value) public returns (bool success) {
//         _transfer(msg.sender, _to, _value);
//         return true;
//     }

//     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
//         require(_allowances[_from][msg.sender] >= _value, "account doesn't allow enough balance");
//         unchecked {
//             _allowances[_from][msg.sender] -= _value;
//         }
//         _transfer(_from, _to, _value);
//         return true;
//     }

//     function approve(address _spender, uint256 _value) public returns (bool success) {
//         require(_spender != address(0), "not a valid spender");
//         _allowances[msg.sender][_spender] = _value;
//         emit Approval(msg.sender, _spender, _value);
//         return true;
//     }

//     function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
//         return _allowances[_owner][_spender];
//     }

//     function addValidator(address _validator) public onlyOwner returns(bool success) {
//         require(_validator != address(0), "Validator address cannot be zero");
//         require(!_validators[_validator], "Validator already exists");
//         _validators[_validator] = true;
//         emit ValidatorAdded(_validator);
//         return true;
//     }

//     function removeValidator(address _validator) public onlyOwner returns(bool success) {
//         require(_validators[_validator], "Validator does not exist");
//         _validators[_validator] = false;
//         emit ValidatorRemoved(_validator);
//         return true;
//     }

//     function mintCarbonTokens(address account, uint256 carbonTons) public onlyValidator returns(bool success) {
//         require(account != address(0), "Mint to the zero address");
//         uint256 tokens = carbonTons / 2;
//         _mint(account, tokens * (10 ** decimals()));
//         return true;
//     }

//     function burn(uint256 _value) public returns (bool success) {
//         require(_balances[msg.sender] >= _value, "Insufficient balance to burn");
//         _balances[msg.sender] -= _value;
//         _totalSupply -= _value;
//         emit Burn(msg.sender, _value);
//         emit Transfer(msg.sender, address(0), _value);
//         return true;
//     }

//     function _transfer(address _from, address _to, uint256 _value) internal {
//         require(_to != address(0), "can't transfer to address 0");
//         require(_balances[_from] >= _value, "account doesn't have enough balance");
//         _balances[_from] -= _value;
//         _balances[_to] += _value;
//         emit Transfer(_from, _to, _value);
//     }

//     function _mint(address account, uint256 _amount) internal {
//         require(account != address(0), "you can't mint to address 0");
//         _totalSupply += _amount;
//         _balances[account] += _amount;
//         emit Transfer(address(0), account, _amount);
//     }
// }

// pragma solidity >=0.8.2 <0.9.0;

// // import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// /**
//  * @title Storage
//  * @dev Store & retrieve value in a variable
//  * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
//  */

// // interface ERC20 {
// //     function name() public view  returns (string memory);
// //     function symbol() external view returns (string memory);
// //     function decimals() external view returns (uint8);
// //     function totalSupply() external view returns (uint256);
// //     function balanceOf(address _owner) external view returns (uint256 balance);
// //     function transfer(address _to, uint256 _value) external returns (bool success);
// //     function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
// //     function approve(address _spender, uint256 _value) external returns (bool success);
// //     function allowance(address _owner, address _spender) external view returns (uint256 remaining);

// //     event Transfer(address indexed _from, address indexed _to, uint256 _value);
// //     event Approval(address indexed _owner, address indexed _spender, uint256 _value);

// // }

// // contract TestToken is ERC20 {
// contract Carbon {
//     string private _name;
//     string private _symbol;
//     uint256 private _totalSupply;
//     mapping (address => uint) private _balances;
//     mapping (address => mapping(address => uint256)) _allowances;
//     address _contratOwner;
//     // mapping (address organization => mapping(address => bool)) _organizations;
//     // mapping (address => mapping(address => bool)) _organizations;

//     mapping (address => bool) _validators;

//     error InsufficientBalance(uint256 available, uint256 required);

//     event Transfer(address indexed _from, address indexed _to, uint256 _value);
//     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
//     event ValidatorAdded(address indexed validator);
//     event ValidatorRemoved(address indexed validator);

//     constructor (string memory name_, string memory symbol_, uint256 initialSupply) {
//         _name = name_;
//         _symbol = symbol_;
//         _contratOwner = payable(msg.sender);
//         _mint(_contratOwner, initialSupply * (10 ** decimals()));
//     }
    
//     modifier onlyValidator() {
//         require(_validators[msg.sender], "Only validators can execute this function");
//         _;
//     }

//     function addValidator(address _validator) public onlyOwner {
//         require(_validator != address(0), "Validator address cannot be zero");
//         require(!_validators[_validator], "Validator already exists");

//         _validators[_validator] = true;
//         emit ValidatorAdded(_validator);
//     }

//     function removeValidator(address _validator) public onlyOwner {
//         require(_validators[_validator], "Validator does not exist");

//         _validators[_validator] = false;
//         emit ValidatorRemoved(_validator);
//     }

//     function mintCarbonTokens(address account, uint256 carbonTons) public onlyValidator {
//         require(account != address(0), "Mint to the zero address");
//         uint256 tokens = carbonTons / 2;
//         _mint(account, tokens * (10 ** decimals()));
//     }

//     function name() public view returns (string memory) {
//         return _name;
//     }

//     function symbol() public view returns (string memory) {
//         return _symbol;
//     }

//     function decimals() public pure returns (uint8) {
//         return 18;
//     }

//     function totalSupply() public view returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address _owner) public view returns (uint256) {
//         return _balances[_owner];
//     }

//     function transfer(address _to, uint256 _value) public returns (bool success) {
//         _transfer(msg.sender, _to, _value);
//         return true;
//     }

//     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
//         require(_allowances[_from][msg.sender] >= _value, "account doesn't allow enough ballance");
//         //update the _allowance amount
//         unchecked {
//             _allowances[_from][msg.sender] -= _value;
//         }

//         _transfer(_from, _to, _value);
//         return true;
//     }

//     function approve(address _spender, uint256 _value) public returns (bool success) {
//         require(_spender != address(0), "not a valid spender");
//         _allowances[msg.sender][_spender] = _value;
//         emit Approval(msg.sender, _spender, _value);
//         return true;
//     }

//     function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
//         return _allowances[_owner][_spender];
//     }

//     function _transfer(address _from, address _to, uint256 _value) internal {
//         // retrun error if data is wrong
//         require(_to != address(0), "can't transfer to address 0");
//         require(_balances[_from] >= _value, "account doesn't have enough ballance");

//         _balances[_from] -= _value;
//         _balances[_to] += _value; //check for overflow;

//         // emit Transfer(msg.sender, _to, _value);
//         emit Transfer(_from, _to, _value);

//     }

//     function _mint(address account, uint256 _amount) internal onlyOwner {
//         // check if you need to explicitly check for overflow here
//         require(account != address(0), "you can't mint to address 0");
//         _totalSupply += _amount;
//         _balances[account] += _amount;
//         emit Transfer(address(0), account, _amount);
//     }

//     modifier onlyOwner (){
//         require(
//             msg.sender == _contratOwner,
//             "Only owner can call this function."
//         );
//         _;
//     }

// }