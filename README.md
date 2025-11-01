# 🏦 ZKredit - Zero-Knowledge Credit Assessment and Remittance System

ZKredit is a comprehensive privacy-preserving credit assessment and loan processing system that leverages zero-knowledge proofs to verify user financial information without revealing sensitive data. Built on blockchain technology with multi-agent architecture, it enables secure cross-border remittances with automated compliance and risk assessment.

## 🌟 Key Features

- **Zero-Knowledge Proofs**: Prove creditworthiness without revealing sensitive financial data
- **Multi-Agent System**: Specialized agents for worker onboarding, credit assessment, remittance processing, and receiving
- **Blockchain Integration**: Smart contracts for verifiable credit scoring and loan processing
- **Privacy-Preserving**: Advanced ZK circuits for income verification, credit history, and collateral validation
- **Compliance Ready**: Built-in KYC/AML compliance through ERC-8004 registries
- **Audit Trail**: Immutable logging through Hedera Consensus Service (HCS)
- **Payment Gateway**: x402 payment handling for automated fee processing

## 🏗️ Architecture Overview

```
ZKredit System Architecture
┌─────────────────────────────────────────────────────────────┐
│                     Frontend Layer                         │
│  ┌─────────────┬──────────────┬────────────────────────┐  │
│  │ Next.js App │ ZK Proofs    │ Web3 Integration     │  │
│  │ Dashboards  │ Visualization  │ Wallet Connection    │  │
│  └─────────────┴──────────────┴────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Agent Backend                          │
│  ┌──────────────┬─────────────────┬────────────────────┐ │
│  │ WorkerAgent  │ CreditAssessment │ RemittanceAgent     │ │
│  │ 🔐 ZK Proofs│ 🧠 ZK Verification│ 💸 Route Payments │ │
│  └──────────────┴─────────────────┴────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Smart Contract Layer                      │
│  ┌──────────────┬─────────────────┬────────────────────┐ │
│  │ ZK Verifier  │ ERC-8004 Registries              │ │
│  │ Credit Score │ KYC/Credit/Reputation Systems      │ │
│  └──────────────┴─────────────────┴────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   ZK Circuit Layer                         │
│  ┌──────────────┬─────────────────┬────────────────────┐ │
│  │ Income       │ Credit History  │ Collateral         │ │
│  │ Verification│ Verification    │ Verification       │ │
│  └──────────────┴─────────────────┴────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Package Structure

```bash
zkredit/
├── packages/
│   ├── agent-backend/          # Node.js Multi-Agent System
│   ├── contracts/             # Solidity Smart Contracts
│   ├── frontend/              # Next.js Web Application
│   └── demo/                  # Standalone Demo Scripts
├── zk-circuits/               # Zero-Knowledge Circuits
├── tests/                     # Test Suites
└── docs/                      # Documentation
```

## 🚀 Quick Start

### Prerequisites

- Node.js >= 18.0.0
- pnpm >= 8.0.0
- Docker (for local blockchain)
- Foundry (for smart contract development)

### Installation

```bash
# Clone the repository
git clone https://github.com/cyj0918/zkredit_cyj.git
cd zkredit_cyj

# Install dependencies
pnpm install

# Copy environment variables
cp .env.example .env

# Start local blockchain (in separate terminal)
pnpm run blockchain:start

# Deploy contracts
pnpm run contracts:deploy

# Start the development environment
pnpm run dev
```

### Available Scripts

```bash
# Development
pnpm run dev                    # Start all services in development mode
pnpm run build                  # Build all packages
pnpm run contracts:test         # Run smart contract tests
pnpm run test:unit             # Run unit tests
pnpm run test:integration      # Run integration tests

# Demo Scenarios
pnpm run demo:scenario1         # First remittance scenario
pnpm run demo:scenario2       # Loan application scenario
pnpm run generate-test-data    # Generate test data

# Production
pnpm run contracts:deploy       # Deploy to production network
pnpm run frontend:build       # Build frontend for production
```

## 🎯 System Components

### Agent System
- **WorkerAgent**: Handles identity creation and ZK proof generation
- **CreditAssessmentAgent**: Validates ZK proofs and assesses credit risk
- **RemittanceAgent**: Processes cross-border payments with routing optimization
- **ReceiverAgent**: Manages recipient verification and fund distribution

### ZK Circuits
- **Income Verifier**: Verifies income statements without revealing amounts
- **Credit History**: Validates credit scores while preserving privacy
- **Collateral Verification**: Confirms collateral ownership and value

### Smart Contracts
- **ZKCreditVerifier**: Main verification contract for ZK proofs
- **ERC8004KYCRegistry**: KYC compliance and identity management
- **ERC8004CreditRegistry**: Credit history storage and management
- **ERC8004ReputationRegistry**: Reputation scoring and tracking

## 🧪 Testing

```bash
# Run all tests
pnpm run test

# Run specific test suites
pnpm run test:unit
pnpm run test:integration
pnpm run contracts:test

# Run specific scenarios
cd packages/demo && pnpm run scenario2-loan-application
```

## 📊 Demo Scenarios

### Scenario 1: First Remittance
Demonstrates the complete workflow for a first-time user sending remittances with KYC verification.

### Scenario 2: Loan Application with ZK Proofs
Shows how users can apply for loans using zero-knowledge proofs to protect their financial privacy.

## 🔐 Security Features

- **End-to-End Encryption**: All sensitive data is encrypted in transit and at rest
- **Zero-Knowledge Proofs**: User privacy is preserved through advanced ZK protocols
- **Multi-Sig Authentication**: Critical operations require multiple signatures
- **Audit Logging**: All transactions are logged immutably on Hedera Consensus Service
- **Rate Limiting**: Protection against DoS attacks and abuse

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) - Detailed system architecture
- [ZK Guide](docs/ZK_GUIDE.md) - Zero-knowledge proof implementation details
- [Agent Design](docs/AGENT_DESIGN.md) - Multi-agent system design patterns
- [Demo Scenarios](docs/DEMO_SCENARIO.md) - Complete walkthrough of demo scenarios
- [Deployment Guide](docs/DEPLOYMENT.md) - Production deployment instructions

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [circom](https://github.com/iden3/circom) - Zero-knowledge circuit compiler
- [snarkjs](https://github.com/iden3/snarkjs) - JavaScript zkSNARK implementation
- [Foundry](https://github.com/foundry-rs/foundry) - Ethereum development toolchain
- [Hedera Consensus Service](https://docs.hedera.com/guides) - Distributed consensus platform

## 📞 Support

- 📧 Email: support@zkredit.com
- 💬 Discord: [Join our community](https://discord.gg/zkredit)
- 🐛 Issues: [Report bugs](https://github.com/cyj0918/zkredit_cyj/issues)

---

Made with ❤️ by the ZKredit Team
