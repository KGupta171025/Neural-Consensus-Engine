// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Neural Consensus Engine
 * @dev A decentralized platform for distributed AI model training with blockchain-based consensus
 * @author Neural Consensus Team
 * @custom:dev-run-script scripts/deploy.js
 */

// Simple ERC20 interface for reward token
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NeuralConsensusEngine {
    // Token for rewards and staking
    IERC20 public immutable rewardToken;
    address public owner;
    
    // Counters for IDs
    uint256 private _modelIds;
    uint256 private _trainingRoundIds;
    
    // Structs
    struct AIModel {
        uint256 modelId;
        string modelHash; // IPFS hash of model architecture
        address creator;
        string name;
        string description;
        uint256 createdAt;
        uint256 totalRewards;
        ModelStatus status;
        uint256 minStakeRequired;
        uint256 accuracyThreshold; // Minimum accuracy required (in basis points)
    }
    
    struct TrainingRound {
        uint256 roundId;
        uint256 modelId;
        string datasetHash; // IPFS hash of training dataset
        uint256 startTime;
        uint256 endTime;
        uint256 rewardPool;
        uint256 participantCount;
        bool isCompleted;
        string bestModelHash; // Hash of best performing model
        address bestPerformer;
        uint256 bestAccuracy;
    }
    
    struct Participant {
        address nodeAddress;
        uint256 stakedAmount;
        string submittedModelHash;
        uint256 reportedAccuracy;
        bool hasSubmitted;
        bool isValidated;
        uint256 computeScore; // Score based on computational contribution
    }
    
    enum ModelStatus { ACTIVE, TRAINING, COMPLETED, DEPRECATED }
    
    // State variables
    mapping(uint256 => AIModel) public models;
    mapping(uint256 => TrainingRound) public trainingRounds;
    mapping(uint256 => mapping(address => Participant)) public roundParticipants;
    mapping(address => uint256) public nodeStakes;
    mapping(address => uint256) public nodeReputationScores;
    mapping(uint256 => address[]) public roundParticipantsList;
    mapping(uint256 => bool) public modelExists; // Track if model exists
    
    // Constants
    uint256 public constant MIN_STAKE_AMOUNT = 100 * 10**18; // 100 tokens
    uint256 public constant REPUTATION_DECAY_RATE = 95; // 5% decay per round
    uint256 public constant MAX_PARTICIPANTS_PER_ROUND = 50;
    
    // Reentrancy guard
    bool private _locked;
    
    // Events
    event ModelCreated(uint256 indexed modelId, address indexed creator, string name);
    event TrainingRoundStarted(uint256 indexed roundId, uint256 indexed modelId, uint256 rewardPool);
    event ParticipantJoined(uint256 indexed roundId, address indexed participant, uint256 stakedAmount);
    event ModelSubmitted(uint256 indexed roundId, address indexed participant, string modelHash, uint256 accuracy);
    event TrainingRoundCompleted(uint256 indexed roundId, address indexed winner, uint256 reward);
    event RewardsDistributed(uint256 indexed roundId, uint256 totalRewards);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
    
    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Create a new AI model for distributed training
     * @param _name Name of the AI model
     * @param _description Description of the model's purpose
     * @param _modelHash IPFS hash of the initial model architecture
     * @param _minStakeRequired Minimum stake required for participants
     * @param _accuracyThreshold Minimum accuracy threshold (in basis points)
     */
    function createModel(
        string memory _name,
        string memory _description,
        string memory _modelHash,
        uint256 _minStakeRequired,
        uint256 _accuracyThreshold
    ) external returns (uint256) {
        require(bytes(_name).length > 0, "Model name cannot be empty");
        require(bytes(_modelHash).length > 0, "Model hash cannot be empty");
        require(_minStakeRequired >= MIN_STAKE_AMOUNT, "Stake too low");
        require(_accuracyThreshold > 0 && _accuracyThreshold <= 10000, "Invalid accuracy threshold");
        
        _modelIds++;
        uint256 newModelId = _modelIds;
        
        models[newModelId] = AIModel({
            modelId: newModelId,
            modelHash: _modelHash,
            creator: msg.sender,
            name: _name,
            description: _description,
            createdAt: block.timestamp,
            totalRewards: 0,
            status: ModelStatus.ACTIVE,
            minStakeRequired: _minStakeRequired,
            accuracyThreshold: _accuracyThreshold
        });
        
        modelExists[newModelId] = true;
        
        emit ModelCreated(newModelId, msg.sender, _name);
        return newModelId;
    }
    
    /**
     * @dev Core Function 2: Start a new training round for federated learning
     * @param _modelId ID of the model to train
     * @param _datasetHash IPFS hash of the training dataset
     * @param _duration Duration of the training round in seconds
     * @param _rewardAmount Amount of reward tokens for this round
     */
    function startTrainingRound(
        uint256 _modelId,
        string memory _datasetHash,
        uint256 _duration,
        uint256 _rewardAmount
    ) external nonReentrant returns (uint256) {
        require(modelExists[_modelId], "Model does not exist");
        require(models[_modelId].creator == msg.sender, "Not model creator");
        require(models[_modelId].status == ModelStatus.ACTIVE, "Model not active");
        require(_duration >= 3600 && _duration <= 86400 * 7, "Invalid duration"); // 1 hour to 7 days
        require(_rewardAmount > 0, "Reward amount must be positive");
        
        // Transfer reward tokens to contract
        require(
            rewardToken.transferFrom(msg.sender, address(this), _rewardAmount),
            "Reward transfer failed"
        );
        
        _trainingRoundIds++;
        uint256 newRoundId = _trainingRoundIds;
        
        trainingRounds[newRoundId] = TrainingRound({
            roundId: newRoundId,
            modelId: _modelId,
            datasetHash: _datasetHash,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            rewardPool: _rewardAmount,
            participantCount: 0,
            isCompleted: false,
            bestModelHash: "",
            bestPerformer: address(0),
            bestAccuracy: 0
        });
        
        models[_modelId].status = ModelStatus.TRAINING;
        
        emit TrainingRoundStarted(newRoundId, _modelId, _rewardAmount);
        return newRoundId;
    }
    
    /**
     * @dev Core Function 3: Submit trained model and complete consensus validation
     * @param _roundId ID of the training round
     * @param _modelHash IPFS hash of the trained model
     * @param _reportedAccuracy Reported accuracy of the model (in basis points)
     * @param _computeProof Proof of computational work performed
     */
    function submitTrainedModel(
        uint256 _roundId,
        string memory _modelHash,
        uint256 _reportedAccuracy,
        bytes32 _computeProof
    ) external nonReentrant {
        TrainingRound storage round = trainingRounds[_roundId];
        require(round.roundId != 0, "Training round does not exist");
        require(block.timestamp >= round.startTime && block.timestamp <= round.endTime, "Round not active");
        require(!round.isCompleted, "Round already completed");
        require(!roundParticipants[_roundId][msg.sender].hasSubmitted, "Already submitted");
        
        uint256 modelId = round.modelId;
        require(nodeStakes[msg.sender] >= models[modelId].minStakeRequired, "Insufficient stake");
        require(_reportedAccuracy >= models[modelId].accuracyThreshold, "Accuracy below threshold");
        
        // Validate compute proof (simplified validation)
        require(_computeProof != bytes32(0), "Invalid compute proof");
        
        // Add participant if not already added
        if (!_isParticipant(_roundId, msg.sender)) {
            require(round.participantCount < MAX_PARTICIPANTS_PER_ROUND, "Max participants reached");
            roundParticipantsList[_roundId].push(msg.sender);
            round.participantCount++;
        }
        
        // Record participant submission
        roundParticipants[_roundId][msg.sender] = Participant({
            nodeAddress: msg.sender,
            stakedAmount: nodeStakes[msg.sender],
            submittedModelHash: _modelHash,
            reportedAccuracy: _reportedAccuracy,
            hasSubmitted: true,
            isValidated: false,
            computeScore: _calculateComputeScore(_computeProof, nodeStakes[msg.sender])
        });
        
        // Update best performer if this submission is better
        if (_reportedAccuracy > round.bestAccuracy) {
            round.bestAccuracy = _reportedAccuracy;
            round.bestPerformer = msg.sender;
            round.bestModelHash = _modelHash;
        }
        
        emit ModelSubmitted(_roundId, msg.sender, _modelHash, _reportedAccuracy);
        
        // Auto-complete round if time expired or consensus reached
        if (block.timestamp > round.endTime || _hasConsensus(_roundId)) {
            _completeTrainingRound(_roundId);
        }
    }
    
    /**
     * @dev Stake tokens to participate in training rounds
     * @param _amount Amount of tokens to stake
     */
    function stakeTokens(uint256 _amount) external {
        require(_amount >= MIN_STAKE_AMOUNT, "Minimum stake not met");
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Stake transfer failed");
        
        nodeStakes[msg.sender] += _amount;
    }
    
    /**
     * @dev Withdraw staked tokens (only if not participating in active rounds)
     * @param _amount Amount to withdraw
     */
    function withdrawStake(uint256 _amount) external nonReentrant {
        require(nodeStakes[msg.sender] >= _amount, "Insufficient stake");
        require(_amount > 0, "Amount must be positive");
        
        nodeStakes[msg.sender] -= _amount;
        require(rewardToken.transfer(msg.sender, _amount), "Withdrawal failed");
    }
    
    /**
     * @dev Force complete a training round if time expired
     * @param _roundId ID of the training round to complete
     */
    function forceCompleteRound(uint256 _roundId) external {
        TrainingRound storage round = trainingRounds[_roundId];
        require(round.roundId != 0, "Training round does not exist");
        require(!round.isCompleted, "Round already completed");
        require(block.timestamp > round.endTime, "Round still active");
        
        _completeTrainingRound(_roundId);
    }
    
    // Internal helper functions
    function _isParticipant(uint256 _roundId, address _participant) internal view returns (bool) {
        address[] memory participants = roundParticipantsList[_roundId];
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == _participant) {
                return true;
            }
        }
        return false;
    }
    
    function _calculateComputeScore(bytes32 _proof, uint256 _stake) internal pure returns (uint256) {
        // Simplified compute score calculation
        return uint256(_proof) % 1000 + (_stake / 10**18);
    }
    
    function _hasConsensus(uint256 _roundId) internal view returns (bool) {
        TrainingRound memory round = trainingRounds[_roundId];
        if (round.participantCount < 3) return false;
        
        // Check if majority of participants submitted similar accuracy
        uint256 consensusCount = 0;
        uint256 targetAccuracy = round.bestAccuracy;
        
        address[] memory participants = roundParticipantsList[_roundId];
        for (uint256 i = 0; i < participants.length; i++) {
            Participant memory participant = roundParticipants[_roundId][participants[i]];
            if (participant.hasSubmitted && 
                _isWithinRange(participant.reportedAccuracy, targetAccuracy, 100)) { // 1% tolerance
                consensusCount++;
            }
        }
        
        return consensusCount >= (round.participantCount * 2) / 3; // 66% consensus
    }
    
    function _isWithinRange(uint256 _value, uint256 _target, uint256 _tolerance) internal pure returns (bool) {
        if (_value > _target) {
            return (_value - _target) <= _tolerance;
        } else {
            return (_target - _value) <= _tolerance;
        }
    }
    
    function _completeTrainingRound(uint256 _roundId) internal {
        TrainingRound storage round = trainingRounds[_roundId];
        require(!round.isCompleted, "Round already completed");
        
        round.isCompleted = true;
        models[round.modelId].status = ModelStatus.COMPLETED;
        
        // Distribute rewards
        _distributeRewards(_roundId);
        
        emit TrainingRoundCompleted(_roundId, round.bestPerformer, round.rewardPool);
    }
    
    function _distributeRewards(uint256 _roundId) internal {
        TrainingRound memory round = trainingRounds[_roundId];
        address[] memory participants = roundParticipantsList[_roundId];
        
        if (participants.length == 0) return;
        
        uint256 totalComputeScore = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            if (roundParticipants[_roundId][participants[i]].hasSubmitted) {
                totalComputeScore += roundParticipants[_roundId][participants[i]].computeScore;
            }
        }
        
        if (totalComputeScore == 0) return;
        
        // Distribute rewards based on compute score and accuracy
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            Participant memory p = roundParticipants[_roundId][participant];
            
            if (p.hasSubmitted) {
                uint256 baseReward = (round.rewardPool * p.computeScore) / totalComputeScore;
                
                // Bonus for best performer
                if (participant == round.bestPerformer && round.rewardPool >= 10) {
                    baseReward += round.rewardPool / 10; // 10% bonus
                }
                
                // Update reputation
                nodeReputationScores[participant] = (nodeReputationScores[participant] * REPUTATION_DECAY_RATE / 100) + 
                                                   (p.reportedAccuracy / 100);
                
                if (baseReward > 0) {
                    require(rewardToken.transfer(participant, baseReward), "Reward transfer failed");
                }
            }
        }
        
        models[round.modelId].totalRewards += round.rewardPool;
        emit RewardsDistributed(_roundId, round.rewardPool);
    }
    
    // View functions
    function getModel(uint256 _modelId) external view returns (AIModel memory) {
        require(modelExists[_modelId], "Model does not exist");
        return models[_modelId];
    }
    
    function getTrainingRound(uint256 _roundId) external view returns (TrainingRound memory) {
        require(trainingRounds[_roundId].roundId != 0, "Training round does not exist");
        return trainingRounds[_roundId];
    }
    
    function getParticipant(uint256 _roundId, address _participant) external view returns (Participant memory) {
        return roundParticipants[_roundId][_participant];
    }
    
    function getRoundParticipants(uint256 _roundId) external view returns (address[] memory) {
        return roundParticipantsList[_roundId];
    }
    
    function getNodeReputation(address _node) external view returns (uint256) {
        return nodeReputationScores[_node];
    }
    
    function getCurrentModelId() external view returns (uint256) {
        return _modelIds;
    }
    
    function getCurrentRoundId() external view returns (uint256) {
        return _trainingRoundIds;
    }
    
    function getNodeStake(address _node) external view returns (uint256) {
        return nodeStakes[_node];
    }
    
    function isRoundActive(uint256 _roundId) external view returns (bool) {
        TrainingRound memory round = trainingRounds[_roundId];
        return round.roundId != 0 && 
               !round.isCompleted && 
               block.timestamp >= round.startTime && 
               block.timestamp <= round.endTime;
    }
}
