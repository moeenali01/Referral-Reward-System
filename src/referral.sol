// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ReferralToken.sol";

contract ReferralSystem is AccessControl, ReentrancyGuard {
    // Role definitions
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // State variables
    ReferralToken public immutable token;
    uint256 public referrerReward;
    uint256 public refereeReward;

    // Counter for referral IDs
    uint256 private _referralIdCounter;

    // Storage optimization: Pack smaller variables together in storage slots
    struct UserProfile {
        bytes32 nameHash; // Hash of name for verification
        bytes32 emailHash; // Hash of email for verification
        uint128 totalRewardsEarned;
        uint64 registrationTime;
        uint64 referralCount; // Cache the count to save gas on reads
    }

    // Referral tracking
    mapping(address => bool) public isRegistered;
    mapping(address => address) public referrerOf;
    mapping(address => address[]) private refereesOf;
    mapping(address => UserProfile) public userProfiles;

    // Struct for referral history - optimized for storage
    struct ReferralRecord {
        uint64 id;
        address referee;
        address referrer;
        uint128 reward; // Combined reward amount to save storage
        uint64 timestamp;
    }

    // Referral history storage
    mapping(uint256 => ReferralRecord) public referralRecords;
    mapping(address => uint256[]) public userReferralRecords;

    // Events - optimized to include only essential data
    event UserRegistered(
        uint256 indexed referralId, address indexed referee, address indexed referrer, uint256 timestamp
    );
    event RewardsDistributed(
        uint256 indexed referralId, address indexed referee, address indexed referrer, uint256 reward
    );
    event RewardAmountsUpdated(uint256 newReferrerReward, uint256 newRefereeReward);

    constructor(address _token, uint256 _referrerReward, uint256 _refereeReward) {
        require(_token != address(0), "Invalid token address");

        token = ReferralToken(_token);
        referrerReward = _referrerReward;
        refereeReward = _refereeReward;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function register(string calldata name, string calldata email) external nonReentrant returns (uint256 referralId) {
        address user = msg.sender;

        // Input validation
        require(!isRegistered[user], "User already registered");
        require(bytes(name).length > 0 && bytes(name).length <= 64, "Invalid name length");
        require(bytes(email).length > 0 && bytes(email).length <= 64, "Invalid email length");

        // Create new referral ID
        _referralIdCounter++;
        referralId = _referralIdCounter;

        // Store hashed user data for privacy and gas optimization
        bytes32 nameHash = keccak256(bytes(name));
        bytes32 emailHash = keccak256(bytes(email));

        // Create user profile with optimized storage
        userProfiles[user] = UserProfile({
            nameHash: nameHash,
            emailHash: emailHash,
            totalRewardsEarned: 0,
            registrationTime: uint64(block.timestamp),
            referralCount: 0
        });

        // Create minimal record for user registration
        ReferralRecord memory record = ReferralRecord({
            id: uint64(referralId),
            referee: user,
            referrer: address(0),
            reward: 0,
            timestamp: uint64(block.timestamp)
        });

        referralRecords[referralId] = record;
        userReferralRecords[user].push(referralId);

        // Mark user as registered
        isRegistered[user] = true;

        emit UserRegistered(referralId, user, address(0), block.timestamp);

        return referralId;
    }

    function joinWithReferral(address referralCode, string calldata name, string calldata email)
        external
        nonReentrant
        returns (uint256 referralId)
    {
        address referee = msg.sender;
        address referrer = referralCode;

        // Input validation
        require(!isRegistered[referee], "User already registered");
        require(bytes(name).length > 0 && bytes(name).length <= 64, "Invalid name length");
        require(bytes(email).length > 0 && bytes(email).length <= 64, "Invalid email length");

        // Validate referrer if provided
        bool hasValidReferrer = false;
        if (referrer != address(0)) {
            require(isRegistered[referrer], "Referrer not registered");
            require(referee != referrer, "Self-referral not allowed");
            require(!_isCircularReferral(referrer, referee), "Circular referral detected");
            hasValidReferrer = true;
        }

        // Create new referral ID
        _referralIdCounter++;
        referralId = _referralIdCounter;

        // Store hashed user data
        bytes32 nameHash = keccak256(bytes(name));
        bytes32 emailHash = keccak256(bytes(email));

        // Create user profile with optimized storage
        userProfiles[referee] = UserProfile({
            nameHash: nameHash,
            emailHash: emailHash,
            totalRewardsEarned: hasValidReferrer ? uint128(refereeReward) : 0,
            registrationTime: uint64(block.timestamp),
            referralCount: 0
        });

        // Register the user
        isRegistered[referee] = true;

        // Process valid referral
        if (hasValidReferrer) {
            // Update referral relationships
            referrerOf[referee] = referrer;
            refereesOf[referrer].push(referee);

            // Increment referrer's referral count
            userProfiles[referrer].referralCount++;

            // Update referrer's total rewards
            userProfiles[referrer].totalRewardsEarned += uint128(referrerReward);

            // Create optimized referral record
            uint128 totalReward = uint128(referrerReward + refereeReward);
            ReferralRecord memory record = ReferralRecord({
                id: uint64(referralId),
                referee: referee,
                referrer: referrer,
                reward: totalReward,
                timestamp: uint64(block.timestamp)
            });

            referralRecords[referralId] = record;
            userReferralRecords[referee].push(referralId);
            userReferralRecords[referrer].push(referralId);

            // Distribute rewards
            _distributeRewards(referralId, referee, referrer);
        } else {
            // Create record without referrer
            ReferralRecord memory record = ReferralRecord({
                id: uint64(referralId),
                referee: referee,
                referrer: address(0),
                reward: 0,
                timestamp: uint64(block.timestamp)
            });

            referralRecords[referralId] = record;
            userReferralRecords[referee].push(referralId);
        }

        emit UserRegistered(referralId, referee, referrer, block.timestamp);

        return referralId;
    }

    function _distributeRewards(uint256 referralId, address referee, address referrer) internal {
        // Cache reward values to save gas
        uint256 _refereeReward = refereeReward;
        uint256 _referrerReward = referrerReward;
        uint256 totalReward = _refereeReward + _referrerReward;

        // Mint tokens to referee
        if (_refereeReward > 0) {
            token.mint(referee, _refereeReward);
        }

        // Mint tokens to referrer
        if (_referrerReward > 0) {
            token.mint(referrer, _referrerReward);
        }

        emit RewardsDistributed(referralId, referee, referrer, totalReward);
    }

    function _isCircularReferral(address referrer, address referee) internal view returns (bool) {
        // Gas-optimized check for circular referrals
        address currentReferrer = referrer;
        uint256 depth = 0;

        // Limit depth to prevent DoS attacks
        while (currentReferrer != address(0) && depth < 20) {
            if (currentReferrer == referee) {
                return true;
            }
            currentReferrer = referrerOf[currentReferrer];
            unchecked {
                depth++;
            } // Safe as we limit the loop
        }

        return false;
    }

    function updateRewardAmounts(uint256 newReferrerReward, uint256 newRefereeReward)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        referrerReward = newReferrerReward;
        refereeReward = newRefereeReward;

        emit RewardAmountsUpdated(newReferrerReward, newRefereeReward);
    }

    function getReferrals(address referrer) external view returns (address[] memory) {
        return refereesOf[referrer];
    }

    function getReferralCount(address referrer) external view returns (uint256) {
        return userProfiles[referrer].referralCount;
    }

    function getTotalRewardsEarned(address user) external view returns (uint256) {
        return userProfiles[user].totalRewardsEarned;
    }

    function getUserReferralHistory(address user) external view returns (uint256[] memory) {
        return userReferralRecords[user];
    }

    function getReferralRecordsBatch(uint256[] calldata referralIds)
        external
        view
        returns (ReferralRecord[] memory records)
    {
        uint256 len = referralIds.length;
        records = new ReferralRecord[](len);

        for (uint256 i = 0; i < len;) {
            records[i] = referralRecords[referralIds[i]];
            unchecked {
                i++;
            } // Safe increment to save gas
        }

        return records;
    }

    function getUserStats(address user)
        external
        view
        returns (uint256 referralCount, uint256 totalRewardsEarned, address referrer)
    {
        require(isRegistered[user], "User not registered");

        UserProfile memory profile = userProfiles[user];

        return (profile.referralCount, profile.totalRewardsEarned, referrerOf[user]);
    }

    function addOperator(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, account);
    }

    function removeOperator(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, account);
    }
}
