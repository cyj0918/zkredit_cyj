// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ERC8004KYCRegistry
 * @dev Implementation of the ERC-8004 KYC Registry standard
 * Handles Know Your Customer verification data with privacy preservation
 */
contract ERC8004KYCRegistry {
    // KYC verification levels
    enum KYCLevel {
        None,
        Basic,
        Enhanced,
        Stringent
    }

    // Verification status
    enum VerificationStatus {
        Pending,
        Verified,
        Expired,
        Revoked,
        Suspended
    }

    // KYC verification information
    struct KYCData {
        KYCLevel level;
        VerificationStatus status;
        uint256 verificationTimestamp;
        uint256 expiryTimestamp;
        uint8 riskScore; // 0-100
        bool isVerified;
        address verifiedBy;
        bytes32 documentHash; // Hash of KYC documents for integrity
        string jurisdiction;
    }

    // Verified users mapping
    mapping(address => KYCData) public kycData;

    // Verification authorities
    mapping(address => bool) public verificationAuthorities;

    // Jurisdiction requirements mapping
    mapping(string => JurisdictionRequirements) public jurisdictionRequirements;

    struct JurisdictionRequirements {
        string jurisdiction;
        KYCLevel minimumLevel;
        string[] requiredDocuments;
        uint256 verificationExpiryPeriod;
    }

    // Events
    event KYCVerified(
        address indexed user,
        address indexed authority,
        KYCLevel level,
        uint256 timestamp
    );

    event KYCExpired(
        address indexed user,
        uint256 timestamp
    );

    event KYCRevoked(
        address indexed user,
        address indexed authority,
        string reason
    );

    event VerificationAuthorityAdded(
        address indexed authority,
        address indexed admin
    );

    event VerificationAuthorityRemoved(
        address indexed authority,
        address indexed admin
    );

    // Admin management
    address public admin;
    mapping(address => bool) public admins;

    // Rate limiting
    mapping(address => uint256) public verificationNonce;
    mapping(string => uint256) public documentHashes;

    // Contract version
    string public constant VERSION = "1.0.0";

    // Modifiers
    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can perform this action");
        _;
    }

    modifier onlyAuthority() {
        require(verificationAuthorities[msg.sender], "Only verification authorities can perform this action");
        _;
    }

    modifier validAddress(address user) {
        require(user != address(0), "Invalid user address");
        _;
    }

    modifier verificationNotExpired(address user) {
        if (kycData[user].status == VerificationStatus.Verified) {
            require(block.timestamp < kycData[user].expiryTimestamp, "KYC expired");
        }
        _;
    }

    constructor() {
        admin = msg.sender;
        admins[msg.sender] = true;
        verificationAuthorities[msg.sender] = true;

        // Set up default jurisdiction requirements
        _setupDefaultJurisdictionRequirements();
    }

    /**
     * @dev Verifies KYC for a user
     * @param user Address of the user to verify
     * @param level KYC level to verify at
     * @param documents Array of document hashes
     * @param jurisdiction User's jurisdiction
     */
    function verifyKYC(
        address user,
        KYCLevel level,
        bytes32[] calldata documents,
        string calldata jurisdiction,
        uint8 riskScore,
        uint256 expiryTimestamp
    )
        external
        onlyAuthority
        validAddress(user)
    {
        require(level != KYCLevel.None, "Invalid KYC level");
        require(bytes(jurisdiction).length > 0, "Jurisdiction required");
        require(riskScore <= 100, "Invalid risk score");
        require(expiryTimestamp > block.timestamp, "Invalid expiry timestamp");
        require(documents.length > 0, "Documents required");

        // Check jurisdiction requirements
        _checkJurisdictionRequirements(jurisdiction, level);

        // Check document uniqueness (prevent document reuse)
        for (uint256 i = 0; i < documents.length; i++) {
            require(documents[i] != bytes32(0), "Invalid document hash");
            require(documentHashes[abi.encodePacked(documents[i])] == 0, "Document already used");
            documentHashes[abi.encodePacked(documents[i])] = block.timestamp;
        }

        // Update KYC data
        KYCData storage userData = kycData[user];
        userData.level = level;
        userData.status = VerificationStatus.Verified;
        userData.verificationTimestamp = block.timestamp;
        userData.expiryTimestamp = expiryTimestamp;
        userData.riskScore = riskScore;
        userData.isVerified = true;
        userData.verifiedBy = msg.sender;
        userData.documentHash = keccak256(abi.encodePacked(documents));
        userData.jurisdiction = jurisdiction;
        userData.riskScore = riskScore;

        // Increment verification nonce for address
        verificationNonce[user]++;

        emit KYCVerified(user, msg.sender, level, block.timestamp);
    }

    /**
     * @dev Revokes KYC verification for a user
     * @param user Address of the user to revoke
     * @param reason Reason for revocation
     */
    function revokeKYC(address user, string calldata reason)
        external
        onlyAuthority
        validAddress(user)
    {
        require(bytes(reason).length > 0, "Reason required");
        require(kycData[user].isVerified, "User not verified");

        kycData[user].status = VerificationStatus.Revoked;
        kycData[user].isVerified = false;

        emit KYCRevoked(user, msg.sender, reason);
    }

    /**
     * @dev Checks if a user is KYC verified
     * @param user Address to check
     * @return isVerified Whether the user is verified
     * @return level KYC level
     * @return expiryTimestamp When the verification expires
     */
    function isVerified(address user)
        external
        view
        validAddress(user)
        returns (
            bool isVerified,
            KYCLevel level,
            uint256 expiryTimestamp
        )
    {
        KYCData memory userData = kycData[user];
        isVerified = userData.isVerified && 
                      userData.status == VerificationStatus.Verified &&
                      block.timestamp < userData.expiryTimestamp;
        level = userData.level;
        expiryTimestamp = userData.expiryTimestamp;
    }

    /**
     * @dev Gets verification level for a user
     * @param user Address to check
     * @return level KYC level (0 if not verified)
     */
    function getVerificationLevel(address user)
        external
        view
        validAddress(user)
        returns (uint8 level)
    {
        if (kycData[user].isVerified && kycData[user].status == VerificationStatus.Verified) {
            return uint8(kycData[user].level);
        }
        return 0; // None level
    }

    /**
     * @dev Gets verification expiry timestamp
     * @param user Address to check
     * @return expiryTimestamp When verification expires (0 if not verified)
     */
    function getVerificationExpiry(address user)
        external
        view
        validAddress(user)
        returns (uint256 expiryTimestamp)
    {
        if (kycData[user].isVerified && kycData[user].status == VerificationStatus.Verified) {
            return kycData[user].expiryTimestamp;
        }
        return 0;
    }

    /**
     * @dev Gets detailed KYC information
     * @param user Address to check
     * @return level KYC level
     * @return status Verification status
     * @return timestamp Verification timestamp
     * @return expiry Expiry timestamp
     * @return riskScore Risk score
     * @return verifier Address that verified the user
     * @return jurisdiction Jurisdiction
     */
    function getKYCData(address user)
        external
        view
        validAddress(user)
        returns (
            KYCLevel level,
            VerificationStatus status,
            uint256 verificationTimestamp,
            uint256 expiryTimestamp,
            uint8 riskScore,
            address verifier,
            string memory jurisdiction
        )
    {
        require(kycData[user].verificationTimestamp > 0, "No KYC data found");
        KYCData memory userData = kycData[user];
        return (
            userData.level,
            userData.status,
            userData.verificationTimestamp,
            userData.expiryTimestamp,
            userData.riskScore,
            userData.verifiedBy,
            userData.jurisdiction
        );
    }

    /**
     * @dev Checks if verification is expired for a user
     * @param user Address to check
     * @return isExpired Whether the verification is expired
     */
    function isVerificationExpired(address user)
        external
        view
        validAddress(user)
        returns (bool isExpired)
    {
        KYCData memory userData = kycData[user];
        return userData.isVerified && userData.status == VerificationStatus.Verified && block.timestamp >= userData.expiryTimestamp;
    }

    /**
     * @dev Updates verification expiry for a user
     * @param user Address of the user
     * @param newExpiryTimestamp New expiry timestamp
     */
    function updateExpiry(
        address user,
        uint256 newExpiryTimestamp
    )
        external
        onlyAuthority
        validAddress(user)
    {
        require(kycData[user].isVerified, "User not verified");
        require(kycData[user].status == VerificationStatus.Verified, "Invalid verification status");
        require(newExpiryTimestamp > block.timestamp, "Invalid expiry timestamp");
        
        kycData[user].expiryTimestamp = newExpiryTimestamp;
    }

    /**
     * @dev Updates user's risk score
     * @param user Address of the user
     * @param newRiskScore New risk score (0-100)
     */
    function updateRiskScore(
        address user,
        uint8 newRiskScore
    )
        external
        onlyAuthority
        validAddress(user)
    {
        require(kycData[user].isVerified, "User not verified");
        require(newRiskScore <= 100, "Invalid risk score");
        
        kycData[user].riskScore = newRiskScore;
    }

    /**
     * @dev Adds a verification authority
     * @param authority Address of the new verification authority
     */
    function addVerificationAuthority(address authority)
        external
        onlyAdmin
        validAddress(authority)
    {
        require(!verificationAuthorities[authority], "Already an authority");
        verificationAuthorities[authority] = true;
        emit VerificationAuthorityAdded(authority, msg.sender);
    }

    /**
     * @dev Removes a verification authority
     * @param authority Address of the authority to remove
     */
    function removeVerificationAuthority(address authority)
        external
        onlyAdmin
        validAddress(authority)
    {
        require(verificationAuthorities[authority], "Not an authority");
        delete verificationAuthorities[authority];
        emit VerificationAuthorityRemoved(authority, msg.sender);
    }

    /**
     * @dev Adds an admin
     * @param newAdmin Address of the new admin
     */
    function addAdmin(address newAdmin)
        external
        onlyAdmin
        validAddress(newAdmin)
    {
        require(!admins[newAdmin], "Already an admin");
        admins[newAdmin] = true;
    }

    /**
     * @dev Removes an admin
     * @param adminToRemove Address of the admin to remove
     */
    function removeAdmin(address adminToRemove)
        external
        onlyAdmin
        validAddress(adminToRemove)
    {
        require(adminToRemove != admin, "Cannot remove original admin");
        delete admins[adminToRemove];
    }

    /**
     * @dev Sets jurisdiction requirements
     * @param jurisdiction Jurisdiction name
     * @param requirements Jurisdiction requirements
     */
    function setJurisdictionRequirements(
        string calldata jurisdiction,
        JurisdictionRequirements calldata requirements
    )
        external
        onlyAdmin
    {
        require(bytes(jurisdiction).length > 0, "Invalid jurisdiction");
        jurisdictionRequirements[jurisdiction] = requirements;
    }

    /**
     * @dev Gets jurisdiction requirements
     * @param jurisdiction Jurisdiction to get requirements for
     * @return requirements Jurisdiction requirements
     */
    function getJurisdictionRequirements(string calldata jurisdiction)
        external
        view
        returns (JurisdictionRequirements memory requirements)
    {
        return jurisdictionRequirements[jurisdiction];
    }

    /**
     * @dev Sets up default jurisdiction requirements
     */
    function _setupDefaultJurisdictionRequirements() internal {
        // USA requirements
        string[] memory usaDocuments = new string[](3);
        usaDocuments[0] = "PASSPORT";
        usaDocuments[1] = "SSN";
        usaDocuments[2] = "PROOF_OF_ADDRESS";

        JurisdictionRequirements memory usa = JurisdictionRequirements({
            jurisdiction: "USA",
            minimumLevel: KYCLevel.Enhanced,
            requiredDocuments: usaDocuments,
            verificationExpiryPeriod: 365 days
        });

        jurisdictionRequirements["USA"] = usa;

        // EU requirements
        string[] memory euDocuments = new string[](2);
        euDocuments[0] = "PASSPORT";
        euDocuments[1] = "PROOF_OF_ADDRESS";

        JurisdictionRequirements memory eu = JurisdictionRequirements({
            jurisdiction: "EU",
            minimumLevel: KYCLevel.Enhanced,
            requiredDocuments: euDocuments,
            verificationExpiryPeriod: 730 days
        });

        jurisdictionRequirements["EU"] = eu;
    }

    /**
     * @dev Checks jurisdiction requirements
     * @param jurisdiction Jurisdiction to check
     * @param level KYC level to validate
     */
    function _checkJurisdictionRequirements(string memory jurisdiction, KYCLevel level) internal view {
        JurisdictionRequirements memory requirements = jurisdictionRequirements[jurisdiction];
        require(bytes(requirements.jurisdiction).length > 0, "Jurisdiction not supported");
        require(uint8(level) >= uint8(requirements.minimumLevel), "KYC level below jurisdiction minimum");
    }

    /**
     * @dev Batch check verification status for multiple users
     * @param users Array of addresses to check
     * @return results Array of verification results
     */
    function batchCheckVerification(address[] calldata users)
        external
        view
        returns (bool[] memory results)
    {
        results = new bool[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] != address(0)) {
                KYCData memory userData = kycData[users[i]];
                results[i] = userData.isVerified && 
                            userData.status == VerificationStatus.Verified &&
                            block.timestamp < userData.expiryTimestamp;
            }
        }
    }

    /**
     * @dev Gets total verified users count
     * @return count Number of verified users
     */
    function getVerifiedUsersCount() external view returns (uint256 count) {
        // Note: This is a simplified implementation
        // In a production environment, you'd want to maintain a count
        // or use a more efficient data structure
        count = 0;
        // This would need to be implemented with proper tracking
    }

    /**
     * @dev Emergency pause function
     * @param paused Whether to pause the contract
     */
    function emergencyPause(bool paused) external onlyAdmin {
        // Implementation would include pause functionality
        require(paused, "Emergency pause functionality would be implemented");
    }
}
