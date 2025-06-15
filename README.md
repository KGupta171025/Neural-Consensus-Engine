# Neural Consensus Engine

A decentralized platform for distributed AI model training with blockchain-based consensus mechanisms. This smart contract enables federated learning where multiple participants can collaboratively train AI models while maintaining data privacy and ensuring fair reward distribution.

## Overview

The Neural Consensus Engine facilitates decentralized AI model training by:
- Enabling creation of AI models for distributed training
- Managing training rounds with participant coordination
- Implementing consensus mechanisms for model validation
- Distributing rewards based on contribution and performance
- Maintaining reputation scores for network participants

## Features

### Core Functionality
- **Model Creation**: Deploy AI models for distributed training
- **Training Rounds**: Coordinate federated learning sessions
- **Consensus Validation**: Verify model submissions through majority consensus
- **Reward Distribution**: Fair compensation based on computational contribution
- **Reputation System**: Track participant performance over time
- **Staking Mechanism**: Ensure participant commitment through token staking

### Key Benefits
- **Privacy-Preserving**: Training data remains with participants
- **Decentralized**: No single point of failure or control
- **Incentivized**: Token rewards for quality contributions
- **Transparent**: All activities recorded on blockchain
- **Scalable**: Support for multiple concurrent training rounds

## Smart Contract Architecture

### Main Components

#### AIModel Structure
```solidity
struct AIModel {
    uint256 modelId;
    string modelHash;        // IPFS hash of model architecture
    address creator;
    string name;
    string description;
    uint256 createdAt;
    uint256 totalRewards;
    ModelStatus status;
    uint256 minStakeRequired;
    uint256 accuracyThreshold;
}
```

#### TrainingRound Structure
```solidity
struct TrainingRound {
    uint256 roundId;
    uint256 modelId;
    string datasetHash;      // IPFS hash of training dataset
    uint256 startTime;
    uint256 endTime;
    uint256 rewardPool;
    uint256 participantCount;
    bool isCompleted;
    string bestModelHash;
    address bestPerformer;
    uint256 bestAccuracy;
}
```

#### Participant Structure
```solidity
struct Participant {
    address nodeAddress;
    uint256 stakedAmount;
    string submittedModelHash;
    uint256 reportedAccuracy;
    bool hasSubmitted;
    bool isValidated;
    uint256 computeScore;
}
```

## Usage Guide

### 1. Deploy Contract
Deploy the contract with an ERC20 token address for rewards:
```solidity
NeuralConsensusEngine engine = new NeuralConsensusEngine(rewardTokenAddress);
```

### 2. Create AI Model
```solidity
uint256 modelId = engine.createModel(
    "Image Classifier",
    "CNN model for image classification",
    "QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", // IPFS hash
    1000 * 10**18,  // 1000 tokens minimum stake
    8000            // 80% accuracy threshold
);
```

### 3. Stake Tokens
Participants must stake tokens to join training rounds:
```solidity
// Approve tokens first
rewardToken.approve(engineAddress, stakeAmount);
// Stake tokens
engine.stakeTokens(1000 * 10**18);
```

### 4. Start Training Round
Model creators can initiate training rounds:
```solidity
uint256 roundId = engine.startTrainingRound(
    modelId,
    "QmYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY", // Dataset IPFS hash
    86400,      // 24 hours duration
    10000 * 10**18  // 10,000 tokens reward pool
);
```

### 5. Submit Trained Model
Participants submit their trained models:
```solidity
engine.submitTrainedModel(
    roundId,
    "QmZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ", // Trained model IPFS hash
    8500,       // 85% reported accuracy
    computeProofHash
);
```

## Configuration Parameters

### Constants
- `MIN_STAKE_AMOUNT`: 100 tokens (minimum stake required)
- `REPUTATION_DECAY_RATE`: 95% (5% reputation decay per round)
- `MAX_PARTICIPANTS_PER_ROUND`: 50 participants maximum

### Validation Rules
- Training round duration: 1 hour to 7 days
- Consensus threshold: 66% of participants
- Accuracy tolerance: 1% for consensus validation
- Minimum participants for consensus: 3

## Consensus Mechanism

The platform uses a Byzantine Fault Tolerant consensus approach:

1. **Submission Phase**: Participants submit trained models with accuracy claims
2. **Validation Phase**: Models are cross-validated by other participants
3. **Consensus Phase**: Majority agreement (66%+) determines validity
4. **Reward Phase**: Tokens distributed based on contribution and accuracy

## Reward Distribution

Rewards are distributed based on:
- **Computational Score**: Based on compute proof and stake amount
- **Accuracy Performance**: Higher accuracy receives larger rewards
- **Best Performer Bonus**: 10% additional reward for top performer
- **Reputation Impact**: Performance affects future reputation scores

## Security Features

### Reentrancy Protection
All state-changing functions use reentrancy guards to prevent attacks.

### Stake-Based Security
Participants must stake tokens, creating economic incentive for honest behavior.

### Time-Based Validation
Training rounds have defined start/end times to prevent manipulation.

### Proof of Compute
Simplified compute proof validation ensures actual work was performed.

## Events

The contract emits the following events for monitoring:
- `ModelCreated`: New AI model registered
- `TrainingRoundStarted`: New training round initiated
- `ParticipantJoined`: New participant joined round
- `ModelSubmitted`: Participant submitted trained model
- `TrainingRoundCompleted`: Round finished with winner
- `RewardsDistributed`: Rewards sent to participants

## View Functions

Query contract state using these read-only functions:
- `getModel(uint256 _modelId)`: Get model details
- `getTrainingRound(uint256 _roundId)`: Get training round info
- `getParticipant(uint256 _roundId, address _participant)`: Get participant data
- `getRoundParticipants(uint256 _roundId)`: List all round participants
- `getNodeReputation(address _node)`: Get participant reputation
- `getNodeStake(address _node)`: Get participant stake amount
- `isRoundActive(uint256 _roundId)`: Check if round is currently active

## Prerequisites

### Dependencies
- Solidity ^0.8.19
- ERC20 token contract for rewards
- IPFS for storing model files and datasets

### Development Tools
- Hardhat or Truffle for deployment
- Web3.js or Ethers.js for interaction
- IPFS client for file storage

## Deployment

1. Deploy ERC20 reward token contract
2. Deploy Neural Consensus Engine with token address
3. Transfer initial token supply for rewards
4. Configure model parameters and start training

## License

MIT License - see LICENSE file for details.

## Support

For questions and support, please open an issue in the project repository or contact the Neural Consensus Team.
