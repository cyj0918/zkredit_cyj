# 🎮 Demo Scenarios Walkthrough

This comprehensive guide provides detailed walkthroughs of the two primary demo scenarios available in the ZKredit system, demonstrating the full workflow from user onboarding to completion of loan applications and remittances.

## 📋 Table of Contents

- [Scenario Overview](#scenario-overview)
- [Scenario 1: First Remittance](#scenario-1-first-remittance)
- [Scenario 2: Loan Application with ZK Proofs](#scenario-2-loan-application-with-zk-proofs)
- [Testing the Scenarios](#testing-the-scenarios)
- [Expected Outcomes](#expected-outcomes)
- [Troubleshooting](#troubleshooting)

## 🎯 Scenario Overview

ZKredit provides two main demo scenarios to showcase the system's capabilities:

1. **First Remittance Scenario**: Demonstrates cross-border payment processing with compliance
2. **Loan Application Scenario**: Shows how users can leverage ZK proofs for privacy-preserving loan applications

Each scenario walks through realistic user journeys, highlighting key features like:
- Zero-knowledge proof generation and verification
- Multi-agent coordination
- Blockchain integration
- Privacy-preserving workflows

## 🏃‍♂️ Scenario 1: First Remittance

### Overview
This scenario demonstrates a first-time worker sending money internationally while maintaining privacy through zero-knowledge proofs.

### User Journey
```
Worker Registration → ZK Identity Creation → Compliance Verification → Payment Processing → Receipt
```

### Prerequisites
- Local blockchain running (Ganache/Hardhat)
- ZK circuits compiled and available
- Agent backend services running

### Step-by-Step Walkthrough

```typescript
// packages/demo/scenario1-first-remittance.ts
import { WorkerAgent } from '../agent-backend/src/agents/WorkerAgent';
import { RemittanceAgent } from '../agent-backend/src/agents/RemittanceAgent';
import { generateIncomeProof } from '../frontend/src/hooks/useZKProof';

/**
 * First Remittance Scenario
 * Demonstrates a migrant worker's first international remittance
 */
async function runFirstRemittanceScenario() {
    console.log('🚀 Starting First Remittance Scenario...');
    
    // STEP 1: Initialize System Components
    console.log('📝 Initializing system components...');
    const workerAgent = new WorkerAgent();
    const remittanceAgent = new RemittanceAgent();
    
    // STEP 2: Worker Registration
    console.log('👷‍♂️ Worker Registration...');
    const workerData = {
        firstName: 'Maria',
        lastName: 'Rodriguez',
        email: 'maria.rodriguez@email.com',
        country: 'Philippines',
        employment: 'Domestic Worker',
        monthlyIncome: 45000, // PHP
        duration: 24 // months
    };
    
    const workerIdentity = await workerAgent.createIdentity(workerData);
    console.log(`✅ Worker registered with ID: ${workerIdentity.id}`);
    
    // STEP 3: ZK Identity Creation
    console.log('🔐 Creating zero-knowledge identity...');
    const zkIdentity = await workerAgent.generateZKProof({
        type: 'identity_verification',
        userData: workerData,
        kycLevel: 'basic'
    });
    
    console.log(`✅ ZK identity proof generated: ${zkIdentity.proofId}`);
    
    // STEP 4: Income Verification (ZK Proof)
    console.log('💰 Generating income verification proof...');
    const incomeProof = await workerAgent.generateZKProof({
        type: 'income_verification',
        salary: workerData.monthlyIncome,
        range: { min: 15000, max: 80000 }, // PHP monthly range
        currency: 'PHP',
        proofType: 'range',
        commitment: true
    });
    
    console.log(`✅ Income verification proof created: ${incomeProof.proofId}`);
    
    // STEP 5: Compliance Verification
    console.log('✅ Verifying compliance requirements...');
    const complianceResult = await workerAgent.verifyCompliance({
        identity: zkIdentity,
        incomeProof: incomeProof,
        kycDocument: 'government_ID', // Simulated KYC
        riskAssessment: 'standard'
    });
    
    console.log(`✅ Compliance verified: ${complianceResult.status}`);
    
    // STEP 6: Remittance Request Creation
    console.log('💰 Creating remittance request...');
    const remittanceRequest = {
        senderId: workerIdentity.id,
        recipient: {
            name: 'Juan Rodriguez',
            country: 'Philippines',
            bank: 'Banco de Oro',
            account: '1234567890',
            relationship: 'family',
            purpose: 'education'
        },
        amount: {
            value: 15000, // PHP amount
            currency: 'PHP',
            equivalentUSD: 270
        },
        transferFee: {
            amount: 300, // PHP
            currency: 'PHP',
            percentage: 2,
            flat: true
        },
        exchangeRate: {
            from: 'PHP',
            to: 'PHP',
            rate: 1.0,
            fee: 0.002
        },
        network: 'SWIFT',
        urgency: 'standard',
        processing: 'auto'
    };
    
    const createdRequest = await remittanceAgent.createRemittance(remittanceRequest);
    console.log(`✅ Remittance request created: ${createdRequest.id}`);
    
    // STEP 7: Route Optimization
    console.log('🛤️ Optimizing payment routes...');
    const optimizedRoute = await remittanceAgent.optimizeRoute({
        amount: remittanceRequest.amount,
        recipientCountry: remittanceRequest.recipient.country,
        urgency: remittanceRequest.urgency,
        network: remittanceRequest.network,
        senderCountry: 'Singapore' // Simulated sending location
    });
    
    console.log(`✅ Optimized route: ${optimizedRoute.routeId}`);
    console.log(`   - Processing time: ${optimizedRoute.estimatedTime} hours`);
    console.log(`   - Total fees: ${optimizedRoute.totalFees} PHP`);
    console.log(`   - Exchange rate: ${optimizedRoute.effectiveRate}`);
    
    // STEP 8: Payment Processing
    console.log('💳 Processing payment...');
    const paymentResult = await remittanceAgent.processPayment({
        remittanceId: createdRequest.id,
        route: optimizedRoute,
        authentication: 'biometric', // Simulated
        funding: 'wallet',
        verification: 'zk_compliance'
    });
    
    console.log(`✅ Payment processed successfully!`);
    console.log(`   - Transaction ID: ${paymentResult.transactionId}`);
    console.log(`   - Status: ${paymentResult.status}`);
    console.log(`   - Recipient receives: ${paymentResult.finalAmount} PHP`);
    console.log(`   - Processing fee: ${paymentResult.processingFee} PHP`);
    
    // STEP 9: ZK Proof Verification (Privacy Preservation)
    console.log('🔐 Verifying payment ZK proofs...');
    const zkPaymentProof = paymentResult.proofs.find(p => p.type === 'payment_privacy');
    if (zkPaymentProof) {
        const verification = await remittanceAgent.verifyZKProof(zkPaymentProof);
        console.log(`✅ Payment privacy proof verified: ${verification.valid}`);
    }
    
    // STEP 10: Receipt Generation and Completion
    console.log('📄 Generating receipt...');
    const receipt = await remittanceAgent.generateReceipt({
        transactionId: paymentResult.transactionId,
        format: 'digital',
        blockchain: false,
        zkProof: zkPaymentProof
    });
    
    console.log(`✅ Receipt generated: ${receipt.id}`);
    console.log(`✅ Complete! Remittance from ${workerData.firstName} to family completed.`);
    
    return {
        success: true,
        transactionId: paymentResult.transactionId,
        receipt: receipt,
        processingTime: optimizedRoute.estimatedTime,
        totalFees: paymentResult.processingFee,
        finalAmount: paymentResult.finalAmount
    };
}

// Run scenario when executed directly
if (require.main === module) {
    runFirstRemittanceScenario()
        .then(result => {
            console.log('🎉 Scenario 1 completed successfully!');
            console.log('Transaction ID:', result.transactionId);
            process.exit(0);
        })
        .catch(error => {
            console.error('❌ Scenario 1 failed:', error);
            process.exit(1);
        });
}
```

### Key Features Demonstrated

1. **Privacy-Preserving Identity**: Worker creates ZK identity without revealing personal details
2. **Income Verification**: Proves income range without disclosing exact amount
3. **Route Optimization**: Finds fastest/cheapest payment path
4. **Compliance Integration**: Automatic KYC/AML checks with ZK proofs
5. **ZKP Payment Processing**: Payment privacy maintained through ZK proofs

## 🏠 Scenario 2: Loan Application with ZK Proofs

### Overview
This scenario demonstrates how a user can apply for a loan using zero-knowledge proofs to protect their financial privacy.

### User Journey
```
Loan Application → ZK Proof Generation → Credit Assessment → Loan Decision → Fund Disbursement
```

### Prerequisites
- All ZK circuits compiled and available
- Credit assessment models loaded
- Agent coordination system running

### Step-by-Step Walkthrough

```typescript
// packages/demo/scenario2-loan-application.ts
import { WorkerAgent } from '../agent-backend/src/agents/WorkerAgent';
import { CreditAssessmentAgent } from '../agent-backend/src/agents/CreditAssessmentAgent';
import { generateLoanProof } from '../frontend/src/hooks/useZKProof';

/**
 * Loan Application with ZK Proofs Scenario
 * Demonstrates complete privacy-preserving loan application process
 */
async function runLoanApplicationScenario() {
    console.log('🏦 Starting Loan Application Scenario...');
    
    // STEP 1: User Profile Setup
    console.log('👤 Setting up user profile...');
    const borrower = {
        name: 'Samuel Adewale',
        email: 'samuel.adewale@email.com',
        country: 'Nigeria',
        occupation: 'Software Developer',
        employer: 'TechCorp Ltd',
        duration: 36, // months employed
        maritalStatus: 'single',
        dependents: 0,
        address: '12 Victoria Island, Lagos'
    };
    
    // Financial information (would typically come from verifiable sources)
    const financialData = {
        monthlyIncome: { amount: 750000, currency: 'NGN' }, // ~$1,500
        annualBonus: { amount: 1500000, currency: 'NGN' },    // ~$3,000
        savings: { amount: 5000000, currency: 'NGN' },       // ~$10,000
        assets: { amount: 15000000, currency: 'NGN' },     // ~$30,000
        
        // Private credit information
        creditScore: 745,  // Good credit score
        paymentHistory: 1, // 1 late payment in last 2 years
        debtRatio: 0.25,  // 25% debt-to-income ratio
        creditHistory: 48  // months of credit history
    };
    
    // STEP 2: Initialize System Agents
    console.log('🤖 Initializing system agents...');
    const workerAgent = new WorkerAgent();
    const creditAgent = new CreditAssessmentAgent();
    
    // STEP 3: Identity Verification (ZK Style)
    console.log('🔐 Creating ZK identity for borrower...');
    const zkIdentity = await workerAgent.generateZKProof({
        type: 'identity_verification',
        userData: borrower,
        verificationLevel: 'enhanced',
        kycProvider: 'local_authority',
        biometric: true,
        privacy: 'maximum'
    });
    
    console.log(`✅ ZK identity created: ${zkIdentity.proofId}`);
    console.log(`   - Verification level: ${zkIdentity.verificationLevel}`);
    console.log(`   - Privacy score: ${zkIdentity.privacyScore}`);
    
    // STEP 4: Income Verification ZK Proof
    console.log('💰 Generating income verification proof...');
    const incomeProof = await workerAgent.generateZKProof({
        type: 'income_verification',
        salary: financialData.monthlyIncome.amount,
        bonus: Math.floor(financialData.annualBonus.amount / 12),
        currency: financialData.monthlyIncome.currency,
        
        // Range proof - shows income is within range without exact amount
        range: { 
            min: 500000,  // NGN ~$1,000/month
            max: 1000000  // NGN ~$2,000/month
        },
        
        // Additional constraints
        employmentMonths: borrower.duration,
        minimumMonths: 6,
        employmentVerification: true,
        
        // ZK specific
        commitment: true,
        nullifier: true, // Prevents double spending
        circuits: ['range_proof', 'employment_verification']
    });
    
    console.log(`✅ Income proof generated: ${incomeProof.proofId}`);
    console.log(`   - Shows income in range: ${incomeProof.range.min}-${incomeProof.range.max} NGN`);
    console.log(`   - Verification: ${incomeProof.verified ? 'PASSED' : 'FAILED'}`);
    
    // STEP 5: Credit History ZK Proof
    console.log('📊 Creating credit history proof...');
    const creditProof = await workerAgent.generateZKProof({
        type: 'credit_verification',
        
        // Private inputs (not revealed)
        privateInputs: {
            creditScore: financialData.creditScore,
            paymentDelays: financialData.paymentHistory,
            debtToIncomeRatio: financialData.debtRatio,
            creditHistoryMonths: financialData.creditHistory
        },
        
        // Public thresholds (for verification without revealing details)
        publicInputs: {
            minCreditScore: 700,
            maxAllowedDelays: 3,
            maxDebtRatio: 0.35,
            minHistoryMonths: 24
        },
        
        proofType: 'threshold_exceeded',
        verificationOptions: {
            validateAgainst: 'credit_bureau',
            consistencyCheck: true,
            tamperProof: true
        }
    });
    
    console.log(`✅ Credit history proof created: ${creditProof.proofId}`);
    console.log(`   - Meets minimum credit score threshold: ${creditProof.thresholdMet}`);
    console.log(`   - Creditworthiness verified: ${creditProof.creditworthy ? 'YES' : 'NO'}`);
    
    // STEP 6: Asset Verification ZK Proof
    console.log('🏠 Creating asset verification proof...');
    const assetProof = await workerAgent.generateZKProof({
        type: 'collateral_verification',
        
        // Private asset details
        privateInputs: {
            assetValue: financialData.assets.amount,
            assetType: 'mixed_portfolio',
            ownershipStatus: 'clear_title',
            liquidityScore: 0.7, // 70% liquidity
            marketStability: 'medium'
        },
        
        // Public verification thresholds
        publicInputs: {
            minAssetValue: 10000000, // ~$20,000 minimum
            targetLTVRatio: 0.6,      // Loan-to-Value ratio
            requiredOwnership: true,
            riskRating: 'acceptable'
        },
        
        constraints: {
            noLiens: true,
            provenOwnership: true,
            acceptableLiquidity: true
        },
        
        circuits: ['ownership_verification', 'valuation_range', 'lien_check']
    });
    
    console.log(`✅ Asset verification proof completed: ${assetProof.proofId}`);
    console.log(`   - Asset ownership verified: ${assetProof.ownershipValid}`);
    console.log(`   - Meets loan-to-value requirements: ${assetProof.ltvCompliant}`);
    
    // STEP 7: Prepare Loan Application with ZK Proofs
    console.log('📝 Preparing complete loan application...');
    const loanApplication = {
        borrower: zkIdentity,
        requestedAmount: 2500000, // NGN ~$5,000
        purpose: 'home_expansion',
        termMonths: 24,
        interestType: 'variable',
        
        // ZK proofs package
        proofs: {
            identity: zkIdentity,
            income: incomeProof,
            credit: creditProof,
            collateral: assetProof
        },
        
        // Privacy settings
        privacyLevel: 'maximum',
        disclosureLevel: 'none',
        verificationLevel: 'full_zk'
    };
    
    console.log(`✅ Loan application prepared for: ${loanApplication.requestedAmount} NGN`);
    console.log(`   - Using ZK proofs: ${Object.keys(loanApplication.proofs).length}`);
    console.log(`   - Privacy level: ${loanApplication.privacyLevel}`);
    
    // STEP 8: Credit Assessment with ZK Verification
    console.log('🧠 Processing credit assessment with ZK proofs...');
    const assessment = await creditAgent.assessApplication({
        application: loanApplication,
        proofPackage: loanApplication.proofs,
        
        assessmentType: 'comprehensive',
        riskModel: 'enhanced',
        compliance: 'full',
        
        // Assessment thresholds (public)
        thresholds: {
            minCreditScore: 700,
            maxPaymentDelays: 3,
            maxDebtRatio: 0.35,
            minHistoryMonths: 24,
            minCollateralRatio: 0.3
        },
        
        // ZK verification options
        zkValidation: {
            verifyIndividually: false, // Verify proof package as a whole
            consistencyCheck: true,
            tamperDetection: true,
            proofInterdependence: true
        }
    });
    
    console.log(`✅ Credit assessment completed: ${assessment.decision}`);
    console.log(`   - Assessment score: ${assessment.assessmentScore}/100`);
    console.log(`   - Risk rating: ${assessment.riskRating}`);
    console.log(`   - Confidence: ${assessment.confidence}%`);
    
    // Verify that assessment was done without revealing private data
    const assessmentDetails = await creditAgent.getAssessmentDetails(assessment.assessmentId);
    console.log(`   - Private data revealed: ${Object.keys(assessmentDetails.privateData).length} items`);
    console.log(`   - Decision basis: Only aggregated metrics used`);
    
    // STEP 9: Loan Decision Processing
    console.log('🏦 Processing loan decision...');
    if (assessment.decision === 'approved') {
        const loanOffer = await creditAgent.createLoanOffer({
            applicationId: loanApplication.id,
            assessmentId: assessment.assessmentId,
            
            offerDetails: {
                approvedAmount: assessment.riskAdjustedAmount,
                interestRate: assessment.riskAdjustedRate,
                termMonths: loanApplication.termMonths,
                monthlyPayment: assessment.estimatedMonthlyPayment,
                totalCost: assessment.totalCost
            },
            
            conditions: {
                minimumVerification: 'zk_verified',
                ongoingMonitoring: 'standard',
                repaymentMethod: 'automatic'
            }
        });
        
        console.log(`✅ Loan approved and offer created: ${loanOffer.offerId}`);
        console.log(`   - Approved amount: ${loanOffer.approvedAmount} NGN`);
        console.log(`   - Interest rate: ${loanOffer.interestRate}% annual`);
        console.log(`   - Monthly payment: ${loanOffer.monthlyPayment} NGN`);
        
        // STEP 10: Accept Loan and Fund Disbursement
        console.log('💰 Accepting loan offer and processing disbursement...');
        
        // Create digital signature for loan acceptance
        const loanAcceptance = await workerAgent.signLoanAcceptance({
            loanOfferId: loanOffer.offerId,
            borrowerId: zkIdentity.proofId,
            acceptanceDate: new Date(),
            terms: loanOffer.terms
        });
        
        console.log(`✅ Loan accepted by borrower: ${loanAcceptance.acceptanceId}`);
        
        // Process fund disbursement (privacy-preserving)
        const disbursement = await creditAgent.disburseLoan({
            loanOfferId: loanOffer.offerId,
            borrowerId: borrower.name,
            disbursementDate: new Date(),
            
            disbursementDetails: {
                amount: loanOffer.approvedAmount,
                currency: 'NGN',
                method: 'wire_transfer',
                destination: 'checking_account'
            },
            
            verification: {
                zkIdentityVerified: true,
                proofsValid: true,
                loanAcceptanceValid: true,
                complianceComplete: true
            }
        });
        
        console.log(`✅ Funds disbursed to borrower: ${disbursement.disbursementId}`);
        console.log(`   - Amount: ${disbursement.amount} NGN`);
        console.log(`   - Status: ${disbursement.status}`);
        console.log(`   - Timeline: ${disbursement.estimatedClearance} hours`);
        
        // Complete privacy verification
        const privacyAudit = await creditAgent.auditPrivacy({
            loanId: disbursement.loanId,
            zkProofIds: [zkIdentity.proofId, incomeProof.proofId, creditProof.proofId, assetProof.proofId],
            auditScope: 'full'
        });
        
        console.log(`\n🛡️ Privacy Audit Results:`);
        console.log(`   - Personal data exposed: ${privacyAudit.personalDataExposed} items`);
        console.log(`   - Financial data exposed: ${privacyAudit.financialDataExposed} items`);
        console.log(`   - Identity linked to loan: ${privacyAudit.identityLink ? 'YES' : 'NO'}`);
        console.log(`   - Overall privacy score: ${privacyAudit.privacyScore}/10`);
        
        return {
            success: true,
            loanId: disbursement.loanId,
            offerId: loanOffer.offerId,
            status: 'funded',
            amount: disbursement.amount,
            privacyScore: privacyAudit.privacyScore,
            monthlyPayment: loanOffer.monthlyPayment,
            termMonths: loanOffer.termMonths
        };
        
    } else {
        console.log(`❌ Loan application declined: ${assessment.decision}`);
        console.log(`   - Reason: ${assessment.reason}`);
        console.log(`   - Alternative suggestion: ${assessment.alternatives || 'None'}`);
        
        return {
            success: false,
            status: 'declined',
            reason: assessment.reason,
            alternatives: assessment.alternatives,
            reapplication: assessment.reevaluationDate
        };
    }
}

// Execute scenario when run directly
if (require.main === module) {
    runLoanApplicationScenario()
        .then(result => {
            if (result.success) {
                console.log('\n🎉 Loan Application Scenario completed successfully!');
                console.log(`💰 Loan approved: ${result.amount} NGN`);
                console.log(`📅 Monthly payment: ${result.monthlyPayment} NGN`);
                console.log(`🛡️ Privacy score: ${result.privacyScore}/10`);
            } else {
                console.log('\n🎉 Loan Application Scenario completed (application declined)');
                console.log(`❌ Reason: ${result.reason}`);
                console.log(`🔢 Can reapply: ${result.reeapplication || 'Immediately'}`);
            }
            process.exit(0);
        })
        .catch(error => {
            console.error('❌ Loan Application Scenario failed:', error);
            process.exit(1);
        });
}
```

### Key Features Demonstrated

1. **Privacy-Preserving Application**: Loan application without revealing sensitive financial data
2. **ZK Income Proof**: Income verification without exact amounts
3. **ZK Credit Proof**: Creditworthiness assessment while maintaining privacy
4. **ZK Collateral Proof**: Asset verification keeping portfolio private
5. **Assessment Transparency**: Credit decisions based on aggregated metrics only

## 🧪 Testing the Scenarios

### Manual Testing

```bash
# Test First Remittance Scenario
cd packages/demo
npm run scenario1
# or
node scenario1-first-remittance.ts

# Test Loan Application Scenario
npm run scenario2
# or
node scenario2-loan-application.ts
```

### Integration Testing

```typescript
// tests/integration/scenario-tests.test.ts
describe('ZK Credit Demo Scenarios', () => {
    let systemHealth: SystemHealth;
    
    beforeAll(async () => {
        // Initialize test environment
        systemHealth = await initializeTestSystem();
        expect(systemHealth.status).toBe('healthy');
    });

    test('First Remittance Scenario - Complete Workflow', async () => {
        const scenario = await import('../demo/scenario1-first-remittance');
        const result = await scenario.runFirstRemittanceScenario();
        
        expect(result.success).toBe(true);
        expect(result.transactionId).toBeDefined();
        expect(result.processingTime).toBeLessThan(48); // hours
        expect(result.totalFees).toBeGreaterThan(0);
        
        // Verify ZK proofs were used
        expect(result.zkProofId).toBeDefined();
        expect(result.verificationSuccess).toBe(true);
    });

    test('Loan Application Scenario - Privacy Preservation', async () => {
        const scenario = await import('../demo/scenario2-loan-application');
        const result = await scenario.runLoanApplicationScenario();
        
        if (result.success) {
            expect(result.loanId).toBeDefined();
            expect(result.privacyScore).toBeGreaterThanOrEqual(8); // High privacy
            expect(result.monthlyPayment).toBeGreaterThan(0);
            
            // Verify private data was protected
            const exposedDataCount = result.privacySummary.exposedItems;
            expect(exposedDataCount).toBe(0); // No personal data exposed
        } else {
            expect(result.reason).toBeDefined();
            expect(result.alternatives).toBeTruthy();
        }
    });
});
```

### Load Testing Scenarios

```typescript
// tests/load/scenarios-load.test.ts
import { Runner } from 'artillery';

async function runLoadTestScenario(
    scenarioName: string, 
    iterations: number = 100,
    concurrentUsers: number = 10
) {
    const config = {
        config: {
            target: 'http://localhost:3000',
            phases: [
                { duration: 60, arrivalRate: concurrentUsers },
                { duration: 120, arrivalRate: concurrentUsers * 2 },
                { duration: 60, arrivalRate: 0 }
            ],
            variables: {
                scenarioName
            }
        },
        scenarios: [
            {
                name: scenarioName,
                weight: 100,
                flow: [
                    {
                        post: {
                            url: `/demo/${scenarioName}`,
                            json: {
                                mode: 'load_test',
                                iterations: iterations
                            },
                            expect: {
                                statusCode: 200,
                                body: { success: true }
                            }
                        }
                    }
                ]
            }
        ]
    };
    
    const result = await Runner.run(config);
    
    return {
        scenario: scenarioName,
        metrics: {
            requestsCompleted: result.metrics.completed,
            avgResponseTime: result.metrics.avgResponseTime,
            p95ResponseTime: result.metrics.p95ResponseTime,
            errors: result.metrics.errors,
            avgZKGenTime: result.metrics.zkGenerationTime,
            avgZKVerifyTime: result.metrics.zkVerificationTime
        }
    };
}
```

## 🎯 Expected Outcomes

### First Remittance Scenario Outcomes
- ✅ Payment processed within 2 business days
- ✅ ZK proofs verify without revealing amounts
- ✅ Transaction fees under 3% of principal
- ✅ Complete compliance verification achieved
- ✅ Privacy score above 9/10 maintained

### Loan Application Scenario Outcomes
- ✅ Quick loan decision (within 30 minutes)
- ✅ Zero sensitive data exposure
- ✅ ZK proofs successfully verify all requirements
- ✅ Fair interest rates based on risk assessment
- ✅ High privacy preservation (privacy score 9+/10)

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue: ZK Proof Generation Takes Too Long

```bash
# Check circuit compilation
cd zk-circuits/
ls -la complied/

# Verify proving keys exist
ls complied/*.zkey | wc -l
# Should show multiple zkey files

# If missing, recompile circuits
circom income_verifier.circom --r1cs --wasm --sym
snarkjs groth16 setup income_verifier.r1cs pot12_beacon.ptau income_verifier.zkey
snarkjs zkey export verificationkey income_verifier.zkey income_verification_key.json
```

#### Issue: Agent Communication Failures

```typescript
// Check agent registration
const registry = new AgentRegistry();
const agents = await registry.discover('all');
console.log('Registered agents:', agents.length);

// Verify message queue connectivity
const mq = new MessageQueue();
await mq.ping();
```

#### Issue: Blockchain Connection Problems

```bash
# Check network connectivity
curl -X POST http://localhost:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Verify contracts are deployed
cd packages/contracts/
forge script script/CheckDeployment.s.sol --rpc-url localhost:8545 --broadcast
```

#### Issue: Privacy Audit Fails

```typescript
// Verify ZK proof types
const proofTypes = ['identity', 'income', 'credit', 'collateral'];
const agent = new ZKProofService();

for (const type of proofTypes) {
    const proof = await agent.generateZKProof(type, testData);
    console.log(`${type} proof validation:`, proof.privateInputsCount === 0);
}
```

### Performance Optimization Tips

1. **Circuit Optimization**:
   - Use efficient range proof algorithms
   - Minimize circuit constraints
   - Compile circuits with optimization flags

2. **Caching Strategies**:
   - Cache frequently used ZK proofs
   - Implement LRU cache for proof validation
   - Pre-compute verification keys

3. **Parallel Processing**:
   - Generate different proof types in parallel
   - Use worker threads for ZK proof generation
   - Implement batch verification for multiple proofs

### Monitoring Commands

```bash
# Monitor system health
curl http://localhost:3000/api/health

# Check agent status
curl http://localhost:3000/api/agents/status

# Monitor ZK proof performance
curl http://localhost:3000/api/zk/performance

# Check message queue status
curl http://localhost:3000/api/messages/status
```

This comprehensive demo guide provides everything needed to understand, run, and troubleshoot the ZKredit demo scenarios, showcasing the powerful privacy-preserving capabilities of the system.
