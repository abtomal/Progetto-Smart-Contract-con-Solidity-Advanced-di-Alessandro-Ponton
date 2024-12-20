// Sources flattened with hardhat v2.22.17 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.1.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File contracts/DAOMetraToken.sol

// Original license: SPDX_License_Identifier: MIT
// 

pragma solidity ^0.8.0;
contract DAOMetraToken is IERC20 {
    // Variabili di stato del token
    string public name = "Demtoken";
    string public symbol = "DMTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Variabile admin per la gestione del contratto
    address public admin;

    // Dichiariamo l'evento per il cambio di admin
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    // Modifier per limitare l'accesso a certe funzioni solo all'admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor(uint256 _initialSupply) {
        // Impostiamo msg.sender come admin iniziale e assegniamo i token
        admin = msg.sender;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Cannot transfer to zero address");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        require(to != address(0), "Cannot transfer to zero address");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 amount) external onlyAdmin {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external onlyAdmin {
        require(from != address(0), "Cannot burn from zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf[from] >= amount, "Burn amount exceeds balance");
        
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function setDAOAsAdmin(address daoAddress) external onlyAdmin {
        require(daoAddress != address(0), "Cannot set zero address as admin");
        address oldAdmin = admin;
        admin = daoAddress;
        emit AdminChanged(oldAdmin, daoAddress);
    }
}


// File contracts/DAOMetra.sol

// Original license: SPDX_License_Identifier: MIT
// https://sepolia.etherscan.io/address/0x9247C769a73BCe6878a529d92FCf847d5933a775#code

pragma solidity ^0.8.0;
contract DAOMetra {
    DAOMetraToken public token;
    address public admin;
    uint256 public sharePrice;
    bool public saleActive;
    uint256 public totalShares;
    uint256 public constant VOTING_PERIOD = 1 weeks;
    uint256 public constant TIMELOCK_DELAY = 1 days;

    struct Proposal {
        string title;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        bool executed;
        address payable recipient;
        uint256 tokenAmount;
        uint256 createdAt;
        uint256 executionTime;
        bool expired;
        bool queued;
    }

    Proposal[] public proposals;
    mapping(address => uint256) public shares;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    // Nuovo mapping per tracciare le proposte attive
    mapping(uint256 => bool) public isProposalActive;
    // Array per mantenere l'elenco degli ID delle proposte attive
    uint256[] private activeProposalIds;

    event SharesPurchased(address indexed buyer, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, string title, uint256 endTime);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool vote, uint256 weight);
    event ProposalQueued(uint256 indexed proposalId, uint256 executionTime);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalExpired(uint256 indexed proposalId);
    event DAOPaused(address indexed pauser);
    event DAOUnpaused(address indexed unpauser);

    bool public isPaused;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(shares[msg.sender] > 0, "Only DAO members can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "DAO is paused");
        _;
    }

    constructor(address _token, uint256 _sharePrice) {
        admin = msg.sender;
        token = DAOMetraToken(_token);
        sharePrice = _sharePrice;
        saleActive = true;
    }

    function purchaseShares(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(saleActive, "Token sale is not active");
        uint256 cost = sharePrice * amount;
        require(token.transferFrom(msg.sender, address(this), cost), "Transfer failed");
        shares[msg.sender] += amount;
        totalShares += amount;
        emit SharesPurchased(msg.sender, amount);
    }

    function disableSale() external onlyAdmin {
        saleActive = false;
    }

    function createProposal(string memory title, string memory description, address payable recipient, uint256 tokenAmount) external onlyMember {
        uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            title: title,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            executed: false,
            recipient: recipient,
            tokenAmount: tokenAmount,
            createdAt: block.timestamp,
            executionTime: 0,
            expired: false,
            queued: false
        }));
        
        // Aggiungi la proposta all'elenco delle proposte attive
        isProposalActive[proposalId] = true;
        activeProposalIds.push(proposalId);
        
        emit ProposalCreated(proposalId, title, block.timestamp + VOTING_PERIOD);
    }

    function vote(uint256 proposalId, bool support, bool abstain) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");
        require(!proposal.executed && !proposal.expired, "Proposal cannot be voted on");
        require(block.timestamp <= proposal.createdAt + VOTING_PERIOD, "Voting period ended");
        require(!(abstain && support), "Cannot both support and abstain");
        require(abstain || !abstain, "Invalid voting parameters");

        hasVoted[proposalId][msg.sender] = true;
        uint256 weight = shares[msg.sender];

        if (abstain) {
            proposal.abstainVotes += weight;
        } else if (support) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }
        emit VoteCast(msg.sender, proposalId, support, weight);
    }

    function queueProposal(uint256 proposalId) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed && !proposal.expired, "Proposal cannot be queued");
        require(block.timestamp > proposal.createdAt + VOTING_PERIOD, "Voting period not ended");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");
        require(proposal.yesVotes * 100 / totalShares >= 51, "Quorum not met");
        require(!proposal.queued, "Proposal already queued");

        proposal.executionTime = block.timestamp + TIMELOCK_DELAY;
        proposal.queued = true;
        emit ProposalQueued(proposalId, proposal.executionTime);
    }

    function executeProposal(uint256 proposalId) external onlyMember whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed && !proposal.expired, "Proposal cannot be executed");
        require(proposal.queued, "Proposal must be queued first");
        require(block.timestamp >= proposal.executionTime, "Timelock period not ended");

        proposal.executed = true;
        
        // Rimuovi la proposta dall'elenco delle proposte attive
        if (isProposalActive[proposalId]) {
            isProposalActive[proposalId] = false;
            removeFromActiveProposals(proposalId);
        }

        if (proposal.recipient != address(0) && proposal.tokenAmount > 0) {
            require(token.transfer(proposal.recipient, proposal.tokenAmount), "Token transfer failed");
        }
        emit ProposalExecuted(proposalId);
    }

    function getActiveProposals() external view returns (uint256[] memory) {
        return activeProposalIds;
    }

    function removeFromActiveProposals(uint256 proposalId) internal {
        for (uint256 i = 0; i < activeProposalIds.length; i++) {
            if (activeProposalIds[i] == proposalId) {
                // Sposta l'ultimo elemento nella posizione corrente e rimuovi l'ultimo elemento
                activeProposalIds[i] = activeProposalIds[activeProposalIds.length - 1];
                activeProposalIds.pop();
                break;
            }
        }
    }

    function getVotingPower(address member) external view returns (uint256) {
        return shares[member];
    }

    function pauseDAO() external onlyAdmin {
        require(!isPaused, "DAO is already paused");
        isPaused = true;
        emit DAOPaused(msg.sender);
    }

    function unpauseDAO() external onlyAdmin {
        require(isPaused, "DAO is not paused");
        isPaused = false;
        emit DAOUnpaused(msg.sender);
    }
}
