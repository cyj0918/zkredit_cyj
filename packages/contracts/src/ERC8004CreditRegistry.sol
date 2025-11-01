// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ERC8004CreditRegistry
 * @dev Implementation of the ERC-8004 Credit Registry standard
 * Handles credit assessment data with privacy preservation and ZK proof integration
 */
contract ERC8004CreditRegistry {
    // Credit score tier classification
    enum CreditScoreTier {
        NoCredit,
        Poor,        // 300-579
        Fair,        // 580-669
        Good,        // 670-739
        VeryGood,    // 740-799
        Exceptional  // 800-850
    }

    // Credit history status
    enum CreditHistoryStatus {
        NoHistory,
        Positive,
        Mixed,
        Negative,
        Default
    }

    // Verification method for credit data
    enum VerificationMethod {
        Traditional,
        ZeroKnowledge,
        DelegatedAuthority,
        MultiParty
    }

    // Credit information structure
    struct CreditData {
        CreditScoreTier tier;
        CreditHistoryStatus historyStatus;
        uint256 creditScore; // If available, 0 for ZK-proven ranges
        uint256 creditHistoryLength; // in months
        uint256 totalCreditLimit;
        uint256 usedCredit;
        uint256 defaultHistory;
        bool hasBankruptcy;
        bool hasForeclosure;
        uint256 incomeRangeMin; // For income verification
        uint256 incomeRangeMax; // For income verification
        uint256 verificationTimestamp;
        VerificationMethod verificationMethod;
        bytes32 verificationProof; // Hash of verification proof
        bool isActive;
        uint256 lastUpdated;
    }

    // ZK-based credit range proofs
    struct ZKCreditRange {
        uint256 minScore;
        uint256 maxScore;
        bytes32 proofHash;
        uint256 creationTimestamp;
        bool isValid;
    }

    // User credit data
    mapping(address => CreditData) public creditData;

    // ZK credit ranges mapping (for privacy-preserving credit verification)
    mapping(address => ZKCreditRange) public zkCreditRanges;

    // Credit limit recommendations
    mapping(address => uint256) public creditLimitRecommendations;

    // Authorized verifiers
    mapping(address => bool) public verifiers;

    // Credit bureaus mapping
    mapping(string => address) public creditBureaus;

    // Contract owner
    address public owner;

    // Registry metadata
    string public name = "ZKredit Credit Registry";
    string public version = "1.0.0";

    // Events
    event CreditAssessmentUpdated(
        address indexed user,
        CreditScoreTier newTier,
        uint256 timestamp,
        VerificationMethod method
    );

    event ZKCreditRangeVerified(
        address indexed user,
        uint256 minScore,
        uint256 maxScore,
        bytes32 proofHash,
        uint256 timestamp
    );

    event CreditLimitUpdated(
        address indexed user,
        uint256 oldLimit,
        uint256 newLimit,
        address updatedBy
    );

    event VerifierAdded(
        address indexed verifier,
        address indexed addedBy
    );

    event VerifierRemoved(
        address indexed verifier,
        address indexed removedBy
    );

    event CreditBureauAdded(
        string indexed bureauName,
        address indexed bureauAddress
    );

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyVerifier() {
        require(verifiers[msg.sender], "Only authorized verifiers can perform this action");
        _;
    }

    modifier validAddress(address account) {
        require(account != address(0), "Invalid address");
        _;
    }

    modifier creditDataExists(address user) {
        require(creditData[user].lastUpdated > 0, "No credit data found");
        _;
    }

    // Contract initialization
    constructor() {
        owner = msg.sender;
        verifiers[msg.sender] = true;

        // Set up default credit bureaus
        _setupDefaultCreditBureaus();
    }

    /**
     * @dev Updates credit assessment for a user (traditional method)
     * @param user Address of the user
     * @param creditScore Credit score value (0-850)
     * @param tier Credit score tier
     * @param historyStatus Credit history status
     * @param creditHistoryLength Length of credit history in months
     * @param totalCreditLimit Total credit limit available
     * @param usedCredit Amount of credit used
     * @param defaultHistory Default history (0-100)
     * @param hasBankruptcy Whether user has bankruptcy
     * @param hasForeclosure Whether user has foreclosure
     * @param incomeMin Minimum verified income
     * @param incomeMax Maximum verified income
     */
    function updateCreditAssessment(
        address user,
        uint256 creditScore,
        CreditScoreTier tier,
        CreditHistoryStatus historyStatus,
        uint256 creditHistoryLength,
        uint256 totalCreditLimit,
        uint256 usedCredit,
        uint256 defaultHistory,
        bool hasBankruptcy,
        bool hasForeclosure,
        uint256 incomeMin,
        uint256 incomeMax
    )
        external
        onlyVerifier
        validAddress(user)
    {
        // Validate inputs
        _validateCreditInputs(
            creditScore,
            tier,
            creditHistoryLength,
            totalCreditLimit,
            usedCredit,
            defaultHistory
        );

        CreditData storage userCredit = creditData[user];
        
        // Update credit data
        userCredit.tier = tier;
        userCredit.creditScore = creditScore;
        userCredit.historyStatus = historyStatus;
        userCredit.creditHistoryLength = creditHistoryLength;
        userCredit.totalCreditLimit = totalCreditLimit;
        userCredit.usedCredit = usedCredit;
        userCredit.defaultHistory = defaultHistory;
        userCredit.hasBankruptcy = hasBankruptcy;
        userCredit.hasForeclosure = hasForeclosure;
        userCredit.incomeRangeMin = incomeMin;
        userCredit.incomeRangeMax = incomeMax;
        userCredit.verificationTimestamp = block.timestamp;
        userCredit.verificationMethod = VerificationMethod.Traditional;
        userCredit.isActive = true;
        userCredit.lastUpdated = block.timestamp;

        emit CreditAssessmentUpdated(user, tier, block.timestamp, VerificationMethod.Traditional);
    }

    /**
     * @dev Updates credit assessment using ZK ranges (privacy-preserving)
     * @param user Address of the user
     * @param scoreTier Credit score tier
     * @param historyStatus Credit history status
     * @param defaultHistory Default history
     * @param bankruptcy Whether user has bankruptcy
     * @param foreclosure Whether user has foreclosure
     * @param incomeMin Minimum income range
     * @param incomeMax Maximum income range
     * @param proofHash Hash of ZK proof
     */
    function updateZKCreditAssessment(
        address user,
        CreditScoreTier scoreTier,
        CreditHistoryStatus historyStatus,
        uint256 defaultHistory,
        bool bankruptcy,
        bool foreclosure,
        uint256 incomeMin,
        uint256 incomeMax,
        bytes32 proofHash
    )
        external
        onlyVerifier
        validAddress(user)
    {
        // Validate ZK-based inputs
        require(scoreTier != CreditScoreTier.NoCredit, "Invalid score tier");
        require(proofHash != bytes32(0), "Invalid proof hash");

        CreditData storage userCredit = creditData[user];
        
        // Update using ZK-verified ranges
        userCredit.tier = scoreTier;
        userCredit.historyStatus = historyStatus;
        userCredit.defaultHistory = defaultHistory;
        userCredit.hasBankruptcy = bankruptcy;
        userCredit.hasForeclosure = foreclosure;
        userCredit.incomeRangeMin = incomeMin;
        userCredit.incomeRangeMax = incomeMax;
        userCredit.verificationTimestamp = block.timestamp;
        userCredit.verificationMethod = VerificationMethod.ZeroKnowledge;
        userCredit.verificationProof = proofHash;
        userCredit.isActive = true;
        userCredit.lastUpdated = block.timestamp;

        emit CreditAssessmentUpdated(user, scoreTier, block.timestamp, VerificationMethod.ZeroKnowledge);
    }

    /**
     * @dev Sets ZK-proven credit score range
     * @param user Address of the user
     * @param minScore Minimum score in range
     * @param maxScore Maximum score in range
     * @param proofHash Hash of ZK proof
     * @param isValid Whether the proof is validated
     */
    function setZKCreditRange(
        address user,
        uint256 minScore,
        uint256 maxScore,
        bytes32 proofHash,
        bool isValid
    )
        external
        onlyVerifier
        validAddress(user)
    {
        require(minScore <= maxScore, "Invalid score range");
        require(maxScore <= 850, "Score out of range"); // Max credit score
        require(proofHash != bytes32(0), "Invalid proof hash");

        ZKCreditRange storage userRange = zkCreditRanges[user];
        userRange.minScore = minScore;
        userRange.maxScore = maxScore;
        userRange.proofHash = proofHash;
        userRange.creationTimestamp = block.timestamp;
        userRange.isValid = isValid;

        emit ZKCreditRangeVerified(user, minScore, maxScore, proofHash, block.timestamp);
    }

    /**
     * @dev Gets credit score information
     * @param user Address to check
     * @return tier Credit score tier
     * @return creditScore Credit score value (or 0 for ZK ranges)
     * @return historyStatus Credit history status
     * @return isActive Whether credit data is active
     * @return verificationMethod Method used for verification
     * @return verificationTimestamp When credit was last verified
     */
    function getCreditInfo(address user)
        external
        view
        creditDataExists(user)
        returns (
            CreditScoreTier tier,
            uint256 creditScore,
            CreditHistoryStatus historyStatus,
            bool isActive,
            VerificationMethod verificationMethod,
            uint256 verificationTimestamp
        )
    {
        CreditData memory userCredit = creditData[user];
        return (
            userCredit.tier,
            userCredit.creditScore,
            userCredit.historyStatus,
            userCredit.isActive,
            userCredit.verificationMethod,
            userCredit.verificationTimestamp
        );
    }

    /**
     * @dev Gets detailed credit data
     * @param user Address to check
     * @return creditScore Score value
     * @return tier Score tier
     * @return historyLength Length of credit history
     * @return totalCreditLimit Total credit limit
     * @return usedCredit Used credit
     * @return defaultHistory Default history
     * @return hasBankruptcy Bankruptcy status
     * @return hasForeclosure Foreclosure status
     */
    function getDetailedCreditData(address user)
        external
        view
        creditDataExists(user)
        returns (
            uint256 creditScore,
            CreditScoreTier tier,
            uint256 historyLength,
            uint256 totalCreditLimit,
            uint256 usedCredit,
            uint256 defaultHistory,
            bool hasBankruptcy,
            bool hasForeclosure,
            uint256 verificationTimestamp
        )
    {
        CreditData memory userCredit = creditData[user];
        return (
            userCredit.creditScore,
            userCredit.tier,
            userCredit.creditHistoryLength,
            userCredit.totalCreditLimit,
            userCredit.usedCredit,
            userCredit.defaultHistory,
            userCredit.hasBankruptcy,
            userCredit.hasForeclosure,
            userCredit.verificationTimestamp
        );
    }

    /**
     * @dev Gets ZK credit score range
     * @param user Address to check
     * @param minScore Minimum score in range
     * @param maxScore Maximum score in range
     * @param isValid Whether the range is valid
     * @param proofHash Hash of proof
     * @param creationTimestamp When range was created
     */
    function getZKCreditRange(address user)
        external
        view
        returns (
            uint256 minScore,
            uint256 maxScore,
            bool isValid,
            bytes32 proofHash,
            uint256 creationTimestamp
        )
    {
        ZKCreditRange memory range = zkCreditRanges[user];
        return (
            range.minScore,
            range.maxScore,
            range.isValid,
            range.proofHash,
            range.creationTimestamp
        );
    }

    /**
     * @dev Gets credit limit recommendation for a user
     * @param user Address to check
     * @return recommendedLimit Recommended credit limit
     * @return calculationTimestamp When recommendation was calculated
     */
    function getCreditLimitRecommendation(address user)
        external
        view
        creditDataExists(user)
        returns (
            uint256 recommendedLimit,
            uint256 calculationTimestamp
        )
    {
        return (
            creditLimitRecommendations[user],
            creditData[user].lastUpdated
        );
    }

    /**
     * @dev Sets credit limit recommendation
     * @param user Address of the user
     * @param recommendedLimit Recommended credit limit
     */
    function setCreditLimitRecommendation(
        address user,
        uint256 recommendedLimit
    )
        external
        onlyVerifier
        validAddress(user)
    {
        require(recommendedLimit > 0, "Invalid credit limit");
        
        uint256 oldLimit = creditLimitRecommendations[user];
        creditLimitRecommendations[user] = recommendedLimit;
        
        emit CreditLimitUpdated(user, oldLimit, recommendedLimit, msg.sender);
    }

    /**
     * @dev Gets credit utilization ratio
     * @param user Address to check
     * @return utilizationRatio Credit utilization ratio (0-100)
     * @param isAvailable Whether utilization data is available
     */
    function getCreditUtilization(address user)
        external
        view
        returns (
            uint256 utilizationRatio,
            bool isAvailable
        )
    {
        CreditData memory userCredit = creditData[user];
        if (userCredit.totalCreditLimit > 0 && userCredit.isActive) {
            utilizationRatio = (userCredit.usedCredit * 100) / userCredit.totalCreditLimit;
            isAvailable = true;
        } else {
            utilizationRatio = 0;
            isAvailable = false;
        }
    }

    /**
     * @dev Validates credit score against tier classification
     * @param score Credit score value
     * @param tier Claimed tier
     * @return isValid Whether the tier matches the score
     */
    function validateCreditTier(uint256 score, CreditScoreTier tier)
        external
        pure
        returns (bool isValid)
    {
        if (tier == CreditScoreTier.NoCredit) return score == 0;
        if (tier == CreditScoreTier.Poor) return score >= 300 && score <= 579;
        if (tier == CreditScoreTier.Fair) return score >= 580 && score <= 669;
        if (tier == CreditScoreTier.Good) return score >= 670 && score <= 739;
        if (tier == CreditScoreTier.VeryGood) return score >= 740 && score <= 799;
        if (tier == CreditScoreTier.Exceptional) return score >= 800 && score <= 850;
        return false;
    }

    /**
     * @dev Batch check credit status for multiple users
     * @param users Array of addresses to check
     * @return tiers Array of credit score tiers
     * @return statuses Array of verification statuses
     * @return timestamps Array of verification timestamps
     */
    function batchCheckCredit(address[] calldata users)
        external
        view
        returns (
            CreditScoreTier[] memory tiers,
            bool[] memory statuses,
            uint256[] memory timestamps
        )
    {
        uint256 length = users.length;
        tiers = new CreditScoreTier[](length);
        statuses = new bool[](length);
        timestamps = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            if (users[i] != address(0) && creditData[users[i]].lastUpdated > 0) {
                CreditData memory userCredit = creditData[users[i]];
                tiers[i] = userCredit.tier;
                statuses[i] = userCredit.isActive;
                timestamps[i] = userCredit.verificationTimestamp;
            }
        }
    }

    /**
     * @dev Gets credit risk assessment for a user
     * @param user Address to assess
     * @return riskScore Risk score (0-100, higher is riskier)
     * @param riskTier Risk tier classification
     * @param isHighRisk Whether considered high risk
     * @param assessmentDetails Detailed assessment information
     */
    function getCreditRisk(address user)
        external
        view
        creditDataExists(user)
        returns (
            uint256 riskScore,
            string memory riskTier,
            bool isHighRisk,
            string memory assessmentDetails
        )
    {
        CreditData memory userCredit = creditData[user];
        
        // Risk calculation based on multiple factors
        riskScore = 0;

        // Credit tier impact (40% weight)
        if (userCredit.tier == CreditScoreTier.Poor) riskScore += 40;
        else if (userCredit.tier == CreditScoreTier.Fair) riskScore += 30;
        else if (userCredit.tier == CreditScoreTier.Good) riskScore += 15;
        else if (userCredit.tier == CreditScoreTier.VeryGood) riskScore += 5;
        else if (userCredit.tier == CreditScoreTier.Exceptional) riskScore += 0;

        // Default history impact (30% weight)
        riskScore += (userCredit.defaultHistory * 30) / 100;

        // Bankruptcy/foreclosure impact (20% weight)
        if (userCredit.hasBankruptcy) riskScore += 15;
        if (userCredit.hasForeclosure) riskScore += 10;

        // Utilization impact (10% weight)
        if (userCredit.totalCreditLimit > 0) {
            uint256 utilization = (userCredit.usedCredit * 100) / userCredit.totalCreditLimit;
            if (utilization > 80) riskScore += 10;
            else if (utilization > 60) riskScore += 5;
        }

        // Determine risk classification
        if (riskScore >= 70) {
            riskTier = "HIGH";
            isHighRisk = true;
        } else if (riskScore >= 40) {
            riskTier = "MEDIUM";
            isHighRisk = false;
        } else {
            riskTier = "LOW";
            isHighRisk = false;
        }

        assessmentDetails = string(abi.encodePacked(
            "Credit Score Tier: ", uint256(uint8(userCredit.tier)), " | ",
            "Default History: ", userCredit.defaultHistory.toString(), "% | ",
            "Bankruptcy: ", userCredit.hasBankruptcy ? "Yes" : "No", " | ",
            "Foreclosure: ", userCredit.hasForeclosure ? "Yes" : "No"
        ));
    }

    /**
     * @dev Validates credit input parameters
     * @param creditScore Credit score value
     * @param tier Credit score tier
     * @param creditHistoryLength Length of credit history
     * @param totalCreditLimit Total credit limit
     * @param usedCredit Used credit amount
     * @param defaultHistory Default history
     */
    function _validateCreditInputs(
        uint256 creditScore,
        CreditScoreTier tier,
        uint256 creditHistoryLength,
        uint256 totalCreditLimit,
        uint256 usedCredit,
        uint256 defaultHistory
    ) internal pure {
        require(creditScore <= 850, "Credit score exceeds maximum");
        require(uint8(tier) <= uint8(CreditScoreTier.Exceptional), "Invalid tier");
        require(creditHistoryLength <= 1000, "Credit history too long"); // Max ~83 years
        require(usedCredit <= totalCreditLimit, "Used credit exceeds total limit");
        require(defaultHistory <= 100, "Default history percentage invalid");
    }

    /**
     * @dev Sets verifier authorization status
     * @param verifier Address of the verifier
     * @param authorized Whether to authorize
     */
    function setVerifier(address verifier, bool authorized) external onlyOwner validAddress(verifier) {
        require(verifiers[verifier] != authorized, "No change needed");
        verifiers[verifier] = authorized;
        
        if (authorized) {
            emit VerifierAdded(verifier, msg.sender);
        }
    }

    /**
     * @dev Gets verifier status
     * @param verifier Address to check
     * @return isVerifier Whether address is a verifier
     */
    function isVerifier(address verifier) external view returns (bool isVerifier) {
        return verifiers[verifier];
    }

    /**
     * @dev Sets credit bureau
     * @param bureauName Name of the credit bureau
     * @param bureauAddress Address of the credit bureau contract
     */
    function setCreditBureau(string calldata bureauName, address bureauAddress) external onlyOwner {
        require(bytes(bureauName).length > 0, "Invalid bureau name");
        require(bureauAddress != address(0), "Invalid bureau address");
        creditBureaus[bureauName] = bureauAddress;
        emit CreditBureauAdded(bureauName, bureauAddress);
    }

    /**
     * @dev Gets credit bureau address
     * @param bureauName Name of the credit bureau
     * @return bureauAddress Address of the credit bureau
     */
    function getCreditBureau(string calldata bureauName) external view returns (address bureauAddress) {
        return creditBureaus[bureauName];
    }

    /**
     * @dev Updates contract owner
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner validAddress(newOwner) {
        owner = newOwner;
    }
}

/**
 * @title IERC8004CreditRegistry Interface
 * @dev Interface for the ERC-8004 Credit Registry standard
 */
interface IERC8004CreditRegistry {
    function getCreditTier(address account) external view returns (uint8);
    function getCreditScore(address account) external view returns (uint256);
    function getCreditHistory(address account) external view returns (uint256);
    function isCreditActive(address account) external view returns (bool);
    function getDefaultHistory(address account) external view returns (bool);
}
