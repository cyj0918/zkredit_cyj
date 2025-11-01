// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ERC8004ReputationRegistry
 * @dev Implementation of the ERC-8004 Reputation Registry standard
 * Handles reputation tracking and scoring with transparency and privacy preservation
 */
contract ERC8004ReputationRegistry {
    // Reputation score range and tiers
    enum ReputationTier {
        Unrated,
        MinusTwo,           // -2 to -1.5
        MinusOne,          // -1.5 to -0.5
        Neutral,           // -0.5 to +0.5
        PlusOne,           // +0.5 to +1.5
        PlusTwo,           // +1.5 to +2.0
        Exceptional         // +2.0 and above
    }

    // Reputation events/types
    enum ReputationEventType {
        PositiveReview,      // +1.0 points
        NegativeReview,      // -1.0 points
        VerifiedTransaction,  // +0.5 points
        DefaultEvent,         // -2.0 points
        OnTimePayment,        // +0.2 points
        LatePayment,         // -0.3 points
        CompletenessBoost,     // +0.1 points
        VerificationBonus,    // +0.3 points
        CommunityEngagement   // +0.2 points
    }

    // Verification methods for reputation data
    enum VerificationMethod {
        BlockchainVerified,
        ZeroKnowledge,
        CrowdSourced,
        AuthorityVerified,
        DelegatedVerification
    }

    // Reputation data structure
    struct ReputationData {
        ReputationTier tier;
        int256 score;               // Range approximately -10 to +10
        uint256 scoreTimestamp;
        uint256 positiveEvents;
        uint256 negativeEvents;
        uint256 totalEvents;
        uint256 disputeCount;
        bool isBlacklisted;
        uint256 blacklistExpiry;
        VerificationMethod verificationMethod;
        uint256 lastUpdated;
        address lastUpdatedBy;
    }

    // Dispute management
    struct Dispute {
        bytes32 disputeId;
        address initiator;
        address targetUser;
        string reason;
        uint256 timestamp;
        uint256 votesFor;      // Votes supporting dispute
        uint256 votesAgainst;  // Votes against dispute
        bool isResolved;
        DisputeResolution resolution;
        mapping(address => bool) hasVoted;
    }

    enum DisputeResolution {
        Pending,
        Supported,
        Rejected,
        Invalidated
    }

    // Reputation authority management
    struct ReputationAuthority {
        address authorityAddress;
        string name;
        uint256 authorityLevel;
        uint256 registeredAt;
        bool isActive;
        uint256 totalVotes;
    }

    // Main storage mappings
    mapping(address => ReputationData) public reputationData;
    mapping(bytes32 => Dispute) public disputes;
    mapping(address => ReputationAuthority) public reputationAuthorities;
    mapping(address => bool) public reputationVerifiers;

    // Voting power tracking
    mapping(address => uint256) public votingPower;
    mapping(address => address[]) public userDelegates;

    // Contract metadata
    string public constant NAME = "ZKredit Reputation Registry";
    string public constant VERSION = "1.0.0";
    address public owner;

    // Dispute configuration
    uint256 public constant MIN_DISPUTE_VOTES = 10;
    uint256 public constant DISPUTE_PERIOD = 7 days;
    uint256 public constant SLASHING_PERIOD = 30 days;
    uint256 public constant REPUTATION_DECAY_RATE = 1; // 1% per month

    // Events
    event ReputationUpdated(
        address indexed user,
        int256 newScore,
        ReputationTier newTier,
        ReputationEventType eventType,
        uint256 timestamp
    );

    event DisputeCreated(
        bytes32 indexed disputeId,
        address indexed initiator,
        address indexed targetUser,
        uint256 timestamp
    );

    event DisputeResolved(
        bytes32 indexed disputeId,
        address indexed resolver,
        DisputeResolution resolution,
        uint256 timestamp
    );

    event BlacklistUpdate(
        address indexed user,
        bool isBlacklisted,
        uint256 expiry,
        address indexed updatedBy
    );

    event VerifierAdded(
        address indexed verifier,
        address indexed addedBy
    );

    event VerifierRemoved(
        address indexed verifier,
        address indexed removedBy
    );

    event AuthorityRegistered(
        address indexed authority,
        string name,
        uint256 level,
        uint256 timestamp
    );

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyVerifier() {
        require(reputationVerifiers[msg.sender], "Only reputation verifiers can perform this action");
        _;
    }

    modifier validAddress(address account) {
        require(account != address(0), "Invalid address");
        _;
    }

    modifier notBlacklisted(address user) {
        require(!reputationData[user].isBlacklisted, "User is blacklisted");
        _;
    }

    // Contract initialization
    constructor() {
        owner = msg.sender;
        reputationVerifiers[msg.sender] = true;
        
        // Register contract as authority
        _registerAuthority(msg.sender, "ZKudit Contract", 10);
    }

    /**
     * @dev Updates reputation score for a user
     * @param user Address of the user
     * @param eventType Type of reputation event
     * @param scoreDelta Score change
     * @param verificationProof Proof of verification
     */
    function updateReputation(
        address user,
        ReputationEventType eventType,
        int256 scoreDelta,
        bytes32 verificationProof,
        string memory reason
    )
        external
        onlyVerifier
        validAddress(user)
        notBlacklisted(user)
    {
        require(bytes(verificationProof).length > 0, "Verification proof required");
        require(bytes(reason).length > 0, "Reason required");
        require(scoreDelta >= -10 && scoreDelta <= 10, "Score delta out of range");

        ReputationData storage userData = reputationData[user];
        
        // Update score based on event type
        if (userData.lastUpdated == 0) {
            // New user initialization
            userData.score = scoreDelta;
            userData.tier = _calculateReputationTier(scoreDelta);
            userData.scoreTimestamp = block.timestamp;
            userData.totalEvents = 1;
            userData.verificationMethod = VerificationMethod.BlockchainVerified;
        } else {
            // Apply reputation decay
            int256 decayedScore = _applyReputationDecay(userData.score, userData.lastUpdated);
            userData.score = decayedScore + scoreDelta;
            userData.tier = _calculateReputationTier(userData.score);
            userData.totalEvents += 1;
        }

        // Update event counters
        if (scoreDelta > 0) {
            userData.positiveEvents += 1;
        } else if (scoreDelta < 0) {
            userData.negativeEvents += 1;
        }

        userData.scoreTimestamp = block.timestamp;
        userData.lastUpdated = block.timestamp;
        userData.lastUpdatedBy = msg.sender;

        emit ReputationUpdated(
            user,
            userData.score,
            userData.tier,
            eventType,
            block.timestamp
        );
    }

    /**
     * @dev Creates a reputation dispute
     * @param targetUser User being disputed
     * @param reason Reason for dispute
     * @param evidenceProof Proof of evidence
     */
    function createDispute(
        address targetUser,
        string memory reason,
        bytes32 evidenceProof
    )
        external
        validAddress(targetUser)
    {
        require(creditData[targetUser].lastUpdated > 0, "Target user has no reputation");
        require(bytes(reason).length > 0, "Reason required");
        require(bytes(evidenceProof).length > 0, "Evidence proof required");

        bytes32 disputeId = keccak256(
            abi.encodePacked(msg.sender, targetUser, reason, block.timestamp)
        );

        require(!disputes[disputeId].isResolved, "Dispute already exists");

        Dispute storage newDispute = disputes[disputeId];
        newDispute.disputeId = disputeId;
        newDispute.initiator = msg.sender;
        newDispute.targetUser = targetUser;
        newDispute.reason = reason;
        newDispute.timestamp = block.timestamp;
        newDispute.isResolved = false;
        newDispute.resolution = DisputeResolution.Pending;

        emit DisputeCreated(disputeId, msg.sender, targetUser, block.timestamp);
    }

    /**
     * @dev Votes on a reputation dispute
     * @param disputeId ID of the dispute
     * @param support Whether to support the dispute
     */
    function voteOnDispute(
        bytes32 disputeId,
        bool support
    )
        external
        notBlacklisted(msg.sender)
    {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.initiator != address(0), "Dispute does not exist");
        require(!dispute.isResolved, "Dispute already resolved");
        require(!dispute.hasVoted[msg.sender], "Already voted");
        require(block.timestamp < dispute.timestamp + DISPUTE_PERIOD, "Dispute period expired");

        // Calculate voting power (simplified for demo)
        uint256 voterPower = _calculateVotingPower(msg.sender);
        require(voterPower >= MIN_DISPUTE_VOTES, "Insufficient voting power");

        dispute.hasVoted[msg.sender] = true;

        if (support) {
            dispute.votesFor += voterPower;
        } else {
            dispute.votesAgainst += voterPower;
        }

        // Auto-resolve if either side gets overwhelming support
        if (dispute.votesFor >= dispute.votesAgainst * 3) {
            _resolveDispute(disputeId, DisputeResolution.Supported);
        } else if (dispute.votesAgainst >= dispute.votesFor * 3) {
            _resolveDispute(disputeId, DisputeResolution.Rejected);
        }
    }

    /**
     * @dev Resolves a dispute
     * @param disputeId ID of the dispute to resolve
     * @param resolution Resolution decision
     */
    function resolveDispute(
        bytes32 disputeId,
        DisputeResolution resolution
    )
        external
        onlyOwner
    {
        require(disputes[disputeId].initiator != address(0), "Dispute does not exist");
        require(!disputes[disputeId].isResolved, "Already resolved");

        _resolveDispute(disputeId, resolution);
    }

    /**
     * @dev Blacklists a user
     * @param user Address to blacklist
     * @param reason Reason for blacklisting
     * @param duration Duration of blacklist
     */
    function blacklistUser(
        address user,
        string memory reason,
        uint256 duration
    )
        external
        onlyOwner
        validAddress(user)
    {
        require(bytes(reason).length > 0, "Reason required");
        require(duration > 0 && duration <= 365 days, "Invalid blacklist duration");

        reputationData[user].isBlacklisted = true;
        reputationData[user].blacklistExpiry = block.timestamp + duration;

        emit BlacklistUpdate(user, true, block.timestamp + duration, msg.sender);
    }

    /**
     * @dev Removes blacklist status for a user
     * @param user Address to unblacklist
     */
    function unblacklistUser(address user)
        external
        onlyOwner
        validAddress(user)
    {
        require(reputationData[user].isBlacklisted, "User not blacklisted");

        reputationData[user].isBlacklisted = false;
        reputationData[user].blacklistExpiry = 0;

        emit BlacklistUpdate(user, false, 0, msg.sender);
    }

    /**
     * @dev Adds a reputation verifier
     * @param verifier Address of the verifier
     */
    function addVerifier(address verifier)
        external
        onlyOwner
        validAddress(verifier)
    {
        require(!reputationVerifiers[verifier], "Already a verifier");
        reputationVerifiers[verifier] = true;
        emit VerifierAdded(verifier, msg.sender);
    }

    /**
     * @dev Removes a reputation verifier
     * @param verifier Address to remove
     */
    function removeVerifier(address verifier)
        external
        onlyOwner
        validAddress(verifier)
    {
        require(reputationVerifiers[verifier], "Not a verifier");
        delete reputationVerifiers[verifier];
        emit VerifierRemoved(verifier, msg.sender);
    }

    /**
     * @dev Registers a reputation authority
     * @param authorityAddress Address of the authority
     * @param authorityName Name of the authority
     * @param authorityLevel Authority level (1-10)
     */
    function registerAuthority(
        address authorityAddress,
        string memory authorityName,
        uint8 authorityLevel
    )
        external
        onlyOwner
        validAddress(authorityAddress)
    {
        require(bytes(authorityName).length > 0, "Authority name required");
        require(authorityLevel >= 1 && authorityLevel <= 10, "Invalid authority level");

        _registerAuthority(authorityAddress, authorityName, authorityLevel);
    }

    /**
     * @dev Gets reputation information for a user
     * @param user Address to check
     * @return tier Reputation tier
     * @return score Reputation score
     * @return status Whether user is verified and not blacklisted
     * @return eventCounts Array of positive and negative event counts
     * @return verificationMethod Method used for verification
     * @return timestamp When last updated
     */
    function getReputationInfo(address user)
        external
        view
        returns (
            ReputationTier tier,
            int256 score,
            bool status,
            uint256[3] memory eventCounts,
            VerificationMethod verificationMethod,
            uint256 timestamp
        )
    {
        ReputationData memory userData = reputationData[user];
        bool isActive = userData.lastUpdated > 0 && 
                       !userData.isBlacklisted &&
                       block.timestamp < userData.blacklistExpiry;
        
        return (
            userData.tier,
            userData.score,
            isActive,
            [userData.positiveEvents, userData.negativeEvents, userData.totalEvents],
            userData.verificationMethod,
            userData.lastUpdated
        );
    }

    /**
     * @dev Gets detailed reputation data
     * @param user Address to check
     * @return score Reputation score
     * @return disputeCount Number of disputes
     * @return isBlacklisted Blacklist status
     * @return blacklistExpiry When blacklist expires
     * @return lastUpdated When last updated
     * @return updatedBy Who last updated
     */
    function getDetailedReputation(address user)
        external
        view
        returns (
            int256 score,
            uint256 disputeCount,
            bool isBlacklisted,
            uint256 blacklistExpiry,
            uint256 lastUpdated,
            address updatedBy
        )
    {
        ReputationData memory userData = reputationData[user];
        return (
            userData.score,
            userData.disputeCount,
            userData.isBlacklisted,
            userData.blacklistExpiry,
            userData.lastUpdated,
            userData.lastUpdatedBy
        );
    }

    /**
     * @dev Gets dispute information
     * @param disputeId ID of the dispute
     * @return initiator Address who initiated dispute
     * @return targetUser Address being disputed
     * @return votes Array of vote counts [for, against]
     * @return reason Reason for dispute
     * @return timestamp When created
     * @return isResolved Whether resolved
     * @return resolution Resolution decision
     */
    function getDisputeInfo(bytes32 disputeId)
        external
        view
        returns (
            address initiator,
            address targetUser,
            uint256[2] memory votes,
            string memory reason,
            uint256 timestamp,
            bool isResolved,
            DisputeResolution resolution
        )
    {
        Dispute memory dispute = disputes[disputeId];
        return (
            dispute.initiator,
            dispute.targetUser,
            [dispute.votesFor, dispute.votesAgainst],
            dispute.reason,
            dispute.timestamp,
            dispute.isResolved,
            dispute.resolution
        );
    }

    /**
     * @dev Gets authority information
     * @param authority Address to check
     * @return name Authority name
     * @return level Authority level
     * @return registeredAt When registered
     * @return isActive Whether active
     * @return totalVotes Total votes received
     */
    function getAuthorityInfo(address authority)
        external
        view
        returns (
            string memory name,
            uint256 level,
            uint256 registeredAt,
            bool isActive,
            uint256 totalVotes
        )
    {
        ReputationAuthority memory auth = reputationAuthorities[authority];
        return (
            auth.name,
            auth.authorityLevel,
            auth.registeredAt,
            auth.isActive,
            auth.totalVotes
        );
    }

    /**
     * @dev Batch check reputation status
     * @param users Array of addresses to check
     * @return scores Array of reputation scores
     * @return activeStatus Array of active status
     */
    function batchCheckReputation(address[] calldata users)
        external
        view
        returns (
            bool[] memory blacklisted,
            int256[] memory scores,
            ReputationTier[] memory tiers
        )
    {
        uint256 count = users.length;
        blacklisted = new bool[](count);
        scores = new int256[](count);
        tiers = new ReputationTier[](count);

        for (uint256 i = 0; i < count; i++) {
            if (users[i] != address(0)) {
                ReputationData memory userData = reputationData[users[i]];
                blacklisted[i] = userData.isBlacklisted && block.timestamp < userData.blacklistExpiry;
                scores[i] = userData.score;
                tiers[i] = userData.tier;
            }
        }
    }

    // Internal helper functions

    function _calculateReputationTier(int256 score) internal pure returns (ReputationTier) {
        if (score < -100) return ReputationTier.MinusTwo;
        else if (score < -50) return ReputationTier.MinusOne;
        else if (score < 0) return ReputationTier.Neutral;
        else if (score < 100) return ReputationTier.PlusOne;
        else if (score < 200) return ReputationTier.PlusTwo;
        else return ReputationTier.Exceptional;
    }

    function _applyReputationDecay(int256 currentScore, uint256 lastUpdateTime)
        internal
        view
        returns (int256)
    {
        uint256 monthsElapsed = (block.timestamp - lastUpdateTime) / 30 days;
        if (monthsElapsed == 0) return currentScore;
        
        int256 decay = int256((monthsElapsed * uint256(REPUTATION_DECAY_RATE)) / 100);
        if (currentScore >= 0) {
            return currentScore - decay;
        } else {
            return currentScore + decay; // Decay negative scores towards neutral
        }
    }

    function _calculateVotingPower(address voter) internal view returns (uint256) {
        // Simplified voting power calculation
        if (reputationData[voter].lastUpdated == 0) return 1; // New user gets 1 vote
        if (reputationData[voter].isBlacklisted) return 0; // Blacklisted users can't vote
        
        // Voting power based on reputation
        uint256 reputationPower = uint256(uint8(reputationData[voter].tier) + 1);
        return reputationPower * 10;
    }

    function _resolveDispute(bytes32 disputeId, DisputeResolution resolution) internal {
        Dispute storage dispute = disputes[disputeId];
        dispute.isResolved = true;
        dispute.resolution = resolution;

        emit DisputeResolved(disputeId, msg.sender, resolution, block.timestamp);

        // Update reputation based on dispute resolution
        if (resolution == DisputeResolution.Supported) {
            // TargetUser lost the dispute
            _adjustReputation(dispute.targetUser, -0.5);
        } else if (resolution == DisputeResolution.Rejected) {
            // Initiator falsely accused
            _adjustReputation(dispute.initiator, -0.2);
        }
    }

    function _adjustReputation(address user, int256 adjustment) internal {
        ReputationData storage userData = reputationData[user];
        if (userData.score != 0) {
            userData.score += adjustment;
            userData.tier = _calculateReputationTier(userData.score);
        }
    }

    function _registerAuthority(
        address authorityAddress,
        string memory authorityName,
        uint256 authorityLevel
    ) internal {
        ReputationAuthority storage newAuthority = reputationAuthorities[authorityAddress];
        newAuthority.authorityAddress = authorityAddress;
        newAuthority.name = authorityName;
        newAuthority.authorityLevel = authorityLevel;
        newAuthority.registeredAt = block.timestamp;
        newAuthority.isActive = true;
        newAuthority.totalVotes = 0;

        emit AuthorityRegistered(authorityAddress, authorityName, authorityLevel, block.timestamp);
    }

    function _setupDefaultCreditBureaus() internal {
        // Placeholder for setting up default credit bureaus
        // In a real implementation, this would set up connections to
        // major credit reporting agencies
    }

    /**
     * @dev Interface for ERC-8004 Reputation Registry standard
     */
    function getReputationScore(address account)
        external
        view
        returns (int256 score)
    {
        ReputationData memory userData = reputationData[account];
        return userData.score;
    }

    /**
     * @dev Gets dispute history
     * @param account Address to check
     * @return disputeCount Number of disputes
     */
    function getDisputeHistory(address account)
        external
        view
        returns (uint256 disputeCount)
    {
        return reputationData[account].disputeCount;
    }

    /**
     * @dev Checks blacklist status
     * @param account Address to check
     * @return isBlacklisted Whether user is blacklisted
     */
    function isBlacklisted(address account)
        external
        view
        returns (bool isBlacklisted)
    {
        ReputationData memory userData = reputationData[account];
        return userData.isBlacklisted && block.timestamp < userData.blacklistExpiry;
    }
}
