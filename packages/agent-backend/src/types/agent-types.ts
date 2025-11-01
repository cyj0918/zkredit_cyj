/**
 * Agent Types for ZKredit Multi-Agent System
 * Defines interfaces and enums for all agent-based operations
 */

import { 
  UserData, 
  ZKProof, 
  ZKIdentity, 
  ZKVerificationResult,
  ZKApplication,
  ApplicationStatus,
  VerificationLevel,
  ZKProofType,
  ZKAttributes,
  ZKComplianceProof
} from './zk-types';

// Missing type definitions
export interface ZKIdentityAttributes extends ZKAttributes {}

export interface CreditAttributes {
  /** User's monthly income range (non-revealing proof) */
  incomeRange: {
    min: number;
    max: number;
    currency: string;
  };
  /** Credit score range (non-revealing proof) */
  creditScoreRange: {
    min: number;
    max: number;
  };
  /** Current debt obligations (non-revealing proof) */
  obligationsRange: {
    min: number;
    max: number;
  };
  /** Employment status */
  employment: 'permanent' | 'contract' | 'self_employed' | 'unemployed';
  /** Verification level */
  verificationLevel: VerificationLevel;
  /** Additional attributes */
  attributes: Record<string, unknown>;
}

export interface Condition {
  /** Condition type */
  type: string;
  /** Condition description */
  description: string;
  /** Required actions */
  actions: string[];
  /** Completion criteria */
  criteria: Record<string, unknown>;
  /** Deadline */
  deadline?: number;
  /** Met status */
  met: boolean;
}

export interface PaymentRoute {
  /** Route identifier */
  id: string;
  /** Route steps */
  steps: RouteStep[];
  /** Total estimated cost */
  totalCost: number;
  /** Processing time estimate */
  processingTime: number;
  /** Success probability */
  successProbability: number;
  /** Compliance score */
  complianceScore: number;
}

export interface RouteStep {
  /** Step name */
  name: string;
  /** Agent responsible */
  agentId: string;
  /** Step type */
  type: 'verification' | 'approval' | 'processing' | 'transfer';
  /** Dependencies */
  dependencies: string[];
  /** Estimated duration */
  duration: number;
  /** Cost */
  cost: number;
}

export interface Transaction {
  /** Transaction ID */
  id: string;
  /** Payment request reference */
  paymentId: string;
  /** Transaction hash */
  transactionHash?: string;
  /** Transaction status */
  status: 'pending' | 'submitted' | 'confirmed' | 'failed';
  /** Gas used */
  gasUsed?: number;
  /** Fees */
  fees: FeeStructure;
  /** Metadata */
  metadata: Record<string, unknown>;
}

export interface TransactionResult {
  /** Result status */
  success: boolean;
  /** Transaction details */
  transaction?: Transaction;
  /** Issues encountered */
  issues: string[];
  /** Processing time */
  processingTime: number;
}

export interface EscrowRequest {
  /** Escrow ID */
  id: string;
  /** Amount to hold */
  amount: number;
  /** Currency */
  currency: string;
  /** From address */
  from: string;
  /** To address */
  to: string;
  /** Release conditions */
  releaseConditions: Condition[];
  /** Expiration time */
  expiration: number;
}

export interface EscrowResult {
  /** Escrow status */
  status: 'created' | 'active' | 'released' | 'expired';
  /** Escrow ID */
  escrowId: string;
  /** Held amount */
  amount: number;
  /** Any issues */
  issues: string[];
  /** Next actions required */
  nextActions: string[];
}

export interface FeesDistribution {
  /** Distribution ID */
  id: string;
  /** Individual fee components */
  fees: Record<string, number>;
  /** Total distributed */
  total: number;
  /** Distribution method */
  method: 'proportional' | 'fixed' | 'tiered';
  /** Currency */
  currency: string;
}

export interface FeeOptimization {
  /** Optimized fee structure */
  fees: FeeStructure;
  /** Savings achieved */
  savings: number;
  /** Optimization method used */
  method: string;
  /** Confidence in optimization */
  confidence: number;
}

export interface ComplianceResult {
  /** Compliance status */
  status: 'compliant' | 'non_compliant' | 'needs_review';
  /** Compliance checks passed */
  passedChecks: string[];
  /** Failed checks (if any) */
  failedChecks: string[];
  /** Regulatory requirements met */
  regulatory: string[];
  /** Risk warnings */
  warnings: string[];
}

export interface SanctionsResult {
  /** Sanctions status */
  status: 'clear' | 'flagged' | 'blocked';
  /** Matched entities */
  matched: string[];
  /** Risk classification */
  riskClassification: 'low' | 'medium' | 'high' | 'critical';
  /** Source databases checked */
  databases: string[];
  /** Last updated */
  lastUpdated: number;
}

export interface LimitCheck {
  /** Within transaction limits */
  withinLimits: boolean;
  /** Limit exceeded details */
  exceededDetails: Record<string, {
    limit: number;
    requested: number;
    exceeded: number;
  }>;
  /** Current limits */
  currentLimits: Record<string, number>;
  /** Next reset */
  nextReset?: number;
}

export interface ComplianceReport {
  /** Report ID */
  id: string;
  /** Compliance summary */
  summary: {
    status: 'compliant' | 'non_compliant';
    riskLevel: 'low' | 'medium' | 'high';
    confidence: number;
  };
  /** Detailed findings */
  findings: Record<string, ComplianceResult>;
  /** Recommendations */
  recommendations: string[];
  /** Timestamp */
  timestamp: number;
}

export interface Recipient {
  /** Recipient ID */
  id: string;
  /** Name */
  name: string;
  /** Address or wallet */
  address: string;
  /** Recipient type */
  type: 'bank_account' | 'wallet' | 'mobile_money' | 'cash_pickup';
  /** Country */
  country: string;
  /** Verification status */
  verificationStatus: 'pending' | 'verified' | 'failed';
}

export interface VerificationResult {
  /** Verification result */
  verified: boolean;
  /** Confidence score */
  confidence: number;
  /** Issues found */
  issues: string[];
  /** Next steps */
  nextSteps: string[];
  /** Verification timestamp */
  timestamp: number;
}

export interface BankAccount {
  /** Account number */
  accountNumber: string;
  /** Bank name */
  bankName: string;
  /** Bank country */
  country: string;
  /** Account type */
  type: 'checking' | 'savings' | 'business';
  /** SWIFT/BIC code */
  bic?: string;
  /** Routing number */
  routingNumber?: string;
  /** IBAN */
  iban?: string;
}

export interface FraudCheckResult {
  /** Fraud risk level */
  riskLevel: 'low' | 'medium' | 'high' | 'suspicious';
  /** Fraud indicators found */
  indicators: string[];
  /** Recommendation */
  recommendation: 'proceed' | 'review' | 'block';
  /** Confidence in assessment */
  confidence: number;
}

export interface DistributionResult {
  /** Distribution success */
  success: boolean;
  /** Amount distributed */
  amountDistributed: number;
  /** Recipient confirmations */
  confirmations: VerificationResult[];
  /** Fees incurred */
  fees: FeeStructure;
  /** Issues */
  issues: string[];
}

export interface CrossBorderPayment {
  /** Payment ID */
  id: string;
  /** Source country */
  fromCountry: string;
  /** Destination country */
  toCountry: string;
  /** Cross-border regulation checks */
  regulationChecks: boolean;
  /** Exchange rate information */
  exchangeRate: {
    from: string;
    to: string;
    rate: number;
    markup: number;
  };
  /** Processing time */
  processingTime: number;
}

export interface CrossBorderResult {
  /** Result status */
  status: 'success' | 'failed' | 'delayed';
  /** Processing details */
  details: Record<string, unknown>;
  /** Regulatory compliance */
  compliance: ComplianceResult;
  /** Fees applied */
  fees: FeeStructure;
  /** Issues encountered */
  issues: string[];
}

export interface LocalPayment {
  /** Payment ID */
  id: string;
  /** Local payment method */
  method: 'bank_transfer' | 'mobile_money' | 'wallets' | 'cash' | 'card';
  /** Domestic processing */
  isDomestic: boolean;
  /** Real-time availability */
  realTime: boolean;
  /** Transaction limits */
  limits: {
    minimum: number;
    maximum: number;
  };
}

export interface LocalPaymentResult {
  /** Result status */
  status: 'success' | 'failed' | 'pending';
  /** Processing time */
  processingTime: number;
  /** Fees applied */
  fees: FeeStructure;
  /** Confirmation details */
  confirmation?: Record<string, unknown>;
  /** Issues */
  issues: string[];
}

export interface ConfirmationResult {
  /** Confirmation successful */
  confirmed: boolean;
  /** Confirmation time */
  timestamp: number;
  /** Confirmation method */
  method: 'mobile' | 'email' | 'wallet' | 'bank';
  /** Recipient acknowledgment */
  recipientAcknowledged: boolean;
  /** Any disputes */
  hasDispute: boolean;
}

export interface Dispute {
  /** Dispute ID */
  id: string;
  /** Related transaction */
  transactionId: string;
  /** Dispute type */
  type: 'payment' | 'delivery' | 'quality' | 'fraud';
  /** Dispute reason */
  reason: string;
  /** Evidence provided */
  evidence: string[];
  /** Current status */
  status: 'raised' | 'investigating' | 'resolved' | 'escalated';
  /** Resolution requested */
  requestedResolution: string;
  /** Raised by */
  raisedBy: string;
}

export interface DisputeResolution {
  /** Resolution result */
  result: 'accepted' | 'rejected' | 'partially_accepted' | 'escalated';
  /** Resolution details */
  details: string;
  /** Compensation if any */
  compensation?: number;
  /** Next steps */
  nextSteps: string[];
  /** Resolution timestamp */
  timestamp: number;
}

export interface Payment {
  /** Payment identification */
  paymentId: string;
  /** Payment amount */
  amount: number;
  /** Currency */
  currency: string;
  /** Payment status */
  status: 'pending' | 'confirmed' | 'failed' | 'refunded';
  /** Payer */
  from: string;
  /** Payee */
  to: string;
  /** Transaction method */
  method: string;
  /** Fees paid */
  fees: FeeStructure;
  /** Processing dates */
  processedAt?: number;
  /** Refund reason if applicable */
  refundReason?: string;
}

export interface RefundResult {
  /** Refund status */
  status: 'pending' | 'processed' | 'rejected' | 'partial';
  /** Refund amount */
  refundedAmount: number;
  /** Processing time */
  processingTime: number;
  /** Reason for rejection if applicable */
  rejectReason?: string;
  /** Refund ID */
  refundId?: string;
}

/**
 * Base interface for all agents
 */
export interface Agent {
  /** Unique agent identifier */
  id: string;
  /** Agent type for classification */
  agentType: AgentType;
  /** Current agent status */
  status: AgentStatus;
  /** Agent configuration */
  config: AgentConfig;
  /** Creation timestamp */
  createdAt: number;
  /** Last update timestamp */
  updatedAt: number;
}

/**
 * Worker Agent - Handles user onboarding and identity management
 */
export interface WorkerAgent extends Agent {
  /** User onboarding functionality */
  onboarding: {
    createIdentity(userData: UserData): Promise<Identity>;
    verifyKYCDocuments(documents: Document[]): Promise<KYCResult>;
    generateUserWallet(): Promise<Wallet>;
    activateAccount(identity: Identity): Promise<void>;
  };
  
  /** ZK proof generation */
  zkProofs: {
    generateZKProof(attributes: ZKIdentityAttributes): Promise<ZKProof>;
    verifyLocalZKProof(proof: ZKProof): Promise<ZKVerificationResult>;
    createCommitment(data: UserData): Promise<Commitment>;
  };
  
  /** User data management */
  userData: {
    updateProfile(userId: string, updates: Partial<UserData>): Promise<void>;
    getUserData(userId: string): Promise<UserData>;
    validateEmail(email: string): Promise<boolean>;
  };
}

/**
 * Credit Assessment Agent - Handles credit validation and risk assessment
 */
export interface CreditAssessmentAgent extends Agent {
  /** Proof validation */
  proofValidation: {
    validateZKProof(proof: ZKProof): Promise<ValidationResult>;
    validateIncomeProof(proof: ZKProof): Promise<ValidationResult>;
    validateCreditProof(proof: ZKProof): Promise<ValidationResult>;
    validateCollateralProof(proof: ZKProof): Promise<ValidationResult>;
  };
  
  /** Risk assessment */
  riskAssessment: {
    calculateRiskScore(attributes: CreditAttributes): Promise<RiskScore>;
    determineLoanEligibility(attributes: CreditAttributes): Promise<Eligibility>;
    assessCreditworthiness(attributes: CreditAttributes): Promise<Creditworthiness>;
    generateCreditReport(userId: string): Promise<CreditReport>;
  };
  
  /** Credit decisioning */
  decisioning: {
    approveLoan(application: LoanApplication): Promise<LoanDecision>;
    rejectLoan(application: LoanApplication, reason: string): Promise<LoanDecision>;
    conditionalApprove(application: LoanApplication, conditions: Condition[]): Promise<LoanDecision>;
  };
}

/**
 * Remittance Agent - Handles payment processing and routing
 */
export interface RemittanceAgent extends Agent {
  /** Payment processing */
  payments: {
    createPayment(payment: PaymentRequest): Promise<PaymentResult>;
    optimizeRoute(payment: PaymentRequest): Promise<PaymentRoute>;
    processTransaction(transaction: Transaction): Promise<TransactionResult>;
    handleEscrow(escrow: EscrowRequest): Promise<EscrowResult>;
  };
  
  /** Fee management */
  fees: {
    calculateFees(amount: number, currency: string): Promise<FeeStructure>;
    distributeFees(fees: FeeStructure): Promise<FeesDistribution>;
    optimizeFees(payment: PaymentRequest): Promise<FeeOptimization>;
  };
  
  /** Compliance and regulations */
  compliance: {
    checkCompliance(payment: PaymentRequest): Promise<ComplianceResult>;
    performSanctionsCheck(address: string): Promise<SanctionsResult>;
    validateTransactionLimits(amount: number): Promise<LimitCheck>;
    generateComplianceReport(paymentId: string): Promise<ComplianceReport>;
  };
}

/**
 * Receiver Agent - Handles recipient verification and fund distribution
 */
export interface ReceiverAgent extends Agent {
  /** Recipient verification */
  verification: {
    verifyRecipient(recipient: Recipient): Promise<VerificationResult>;
    validateBankAccount(account: BankAccount): Promise<ValidationResult>;
    performFraudChecks(recipient: Recipient): Promise<FraudCheckResult>;
  };
  
  /** Fund distribution */
  distribution: {
    distributeFunds(transaction: Transaction): Promise<DistributionResult>;
    handleCrossBorderPayment(payment: CrossBorderPayment): Promise<CrossBorderResult>;
    processLocalPayment(payment: LocalPayment): Promise<LocalPaymentResult>;
  };
  
  /** Transaction completion */
  completion: {
    confirmReceipt(paymentId: string): Promise<ConfirmationResult>;
    handleDisputes(dispute: Dispute): Promise<DisputeResolution>;
    initiateRefund(payment: Payment): Promise<RefundResult>;
  };
}

/**
 * Agent configuration and settings
 */
export interface AgentConfig {
  /** Agent name for identification */
  name: string;
  /** Agent description */
  description?: string;
  /** Agent version */
  version: string;
  /** Agent capabilities */
  capabilities: string[];
  /** Maximum concurrent operations */
  maxConcurrency: number;
  /** Operation timeout in milliseconds */
  timeout: number;
  /** Retry configuration */
  retry: RetryPolicy;
  /** Logging level */
  logLevel: LogLevel;
  /** Network endpoints */
  endpoints: Endpoint[];
  /** Agent-specific settings */
  settings: Record<string, unknown>;
}

/**
 * Shared agent types and interfaces
 */
export interface Identity {
  /** Unique identity identifier */
  id: string;
  /** User data associated with identity */
  userData: UserData;
  /** KYC verification status */
  kycLevel: VerificationLevel;
  /** Linked wallet addresses */
  wallets: string[];
  /** Associated ZK proofs */
  zkProofs: ZKProof[];
  /** Creation timestamp */
  createdAt: number;
  /** Last update timestamp */
  updatedAt: number;
}

export interface Document {
  /** Document type */
  type: DocumentType;
  /** Document content/names */
  data: unknown;
  /** Document hash for verification */
  hash: string;
  /** Issued date */
  issuedDate?: Date;
  /** Expiry date */
  expiryDate?: Date;
  /** Verification status */
  verificationStatus: 'pending' | 'verified' | 'failed' | 'expired';
}

export interface KYCResult {
  /** KYC verification status */
  status: 'approved' | 'rejected' | 'pending';
  /** Verification level */
  kycLevel: VerificationLevel;
  /** Expiry date for KYC */
  expiresAt?: Date;
  /** Required documents */
  requiredDocuments?: DocumentType[];
  /** Remarks or comments */
  remarks?: string;
}

export interface ValidationResult {
  /** Validation result */
  valid: boolean;
  /** Score or quality assessment */
  score?: number;
  /** Any issues found */
  issues: string[];
  /** Validation timestamp */
  timestamp: number;
  /** Expiry validity */
  expiresAt?: number;
}

export interface RiskScore {
  /** Overall risk assessment */
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
  /** Numerical risk score (0-1000) */
  score: number;
  /** Risk factors */
  factors: RiskFactor[];
  /** Recommended actions */
  recommendations: string[];
}

export interface CreditReport {
  /** Overall credit grade */
  grade: 'A' | 'B' | 'C' | 'D' | 'F';
  /** Credit score range */
  scoreRange: {
    min: number;
    max: number;
  };
  /** Creditworthiness assessment */
  creditworthiness: 'preferred' | 'standard' | 'subprime' | 'declined';
  /** Key metrics */
  metrics: CreditMetrics;
  /** Recommendations */
  recommendations: string[];
}

export interface LoanApplication {
  /** Application ID */
  id: string;
  /** User ID */
  userId: string;
  /** Requested amount */
  amount: number;
  /** Currency */
  currency: string;
  /** Loan purpose */
  purpose: string;
  /** Duration in months */
  duration: number;
  /** ZK proofs provided */
  proofs: ZKProof[];
  /** Status */
  status: ApplicationStatus;
}

export interface LoanDecision {
  /** Decision type */
  decision: 'approved' | 'rejected' | 'conditional' | 'needs_review';
  /** Approval amount */
  approvedAmount?: number;
  /** Interest rate */
  interestRate?: number;
  /** Loan terms */
  terms?: string[];
  /** Rejection reasons */
  rejectionReasons?: string[];
  /** Decision confidence */
  confidence: number;
  /** Timestamp */
  timestamp: number;
}

export interface PaymentRequest {
  /** Payment ID */
  id: string;
  /** Amount */
  amount: number;
  /** Currency */
  currency: string;
  /** From address */
  from: string;
  /** To address */
  to: string;
  /** Payment type */
  type: PaymentType;
  /** Metadata */
  metadata: Record<string, unknown>;
  /** Expiration time */
  expiresAt?: number;
}

export interface PaymentResult {
  /** Transaction ID */
  transactionId: string;
  /** Current status */
  status: 'pending' | 'processing' | 'completed' | 'failed';
  /** Fees applied */
  fees: FeeStructure;
  /** Final amount */
  finalAmount: number;
  /** Processing time */
  processingTime: number;
  /** Any issues */
  issues: string[];
}

export interface FeeStructure {
  /** Base fee */
  base: number;
  /** Percentage fee */
  percentage: number;
  /** Fixed fees */
  flat: number;
  /** Total fees */
  total: number;
  /** Currency */
  currency: string;
}

// Enums
export enum AgentType {
  WORKER = 'worker',
  CREDIT_ASSESSMENT = 'credit_assessment',
  REMITTANCE = 'remittance',
  RECEIVER = 'receiver'
}

export enum AgentStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  BUSY = 'busy',
  MAINTENANCE = 'maintenance',
  FAILED = 'failed'
}

export enum DocumentType {
  GOVERNMENT_ID = 'government_ID',
  PROOF_OF_ADDRESS = 'proof_of_address',
  BANK_STATEMENT = 'bank_statement',
  EMPLOYMENT_LETTER = 'employment_letter',
  TAX_RETURN = 'tax_return',
  UTILITY_BILL = 'utility_bill'
}

export enum PaymentType {
  DOMESTIC = 'domestic',
  INTERNATIONAL = 'international',
  SAME_DAY = 'same_day',
  STANDARD = 'standard',
  PRIORITY = 'priority'
}

export enum LogLevel {
  ERROR = 'error',
  WARN = 'warn',
  INFO = 'info',
  DEBUG = 'debug',
  TRACE = 'trace'
}

// Utility types and interfaces
export interface Commitment {
  /** Commitment identifier */
  id: string;
  /** Commitment hash */
  hash: string;
  /** Created at */
  createdAt: number;
  /** Expires at */
  expiresAt?: number;
}

export interface Wallet {
  /** Wallet address */
  address: string;
  /** Public key */
  publicKey: string;
  /** Private key (securely stored) */
  privateKey?: string;
  /** Wallet type */
  type: 'ethereum' | 'hedera' | 'bitcoin';
  /** Network */
  network: 'mainnet' | 'testnet' | 'devnet';
}

export interface RetryPolicy {
  /** Maximum number of retries */
  maxRetries: number;
  /** Base delay in milliseconds */
  baseDelay: number;
  /** Maximum delay in milliseconds */
  maxDelay: number;
  /** Backoff multiplier */
  backoffMultiplier: number;
  /** Retry on specific errors */
  retryOn: string[];
}

export interface Endpoint {
  /** Service name */
  name: string;
  /** URL */
  url: string;
  /** Type */
  type: 'rest' | 'grpc' | 'websocket';
  /** Authentication */
  auth: {
    type: 'none' | 'api_key' | 'oauth' | 'bearer';
    credentials?: Record<string, string>;
  };
  /** Health check */
  healthCheck?: string;
}

// Risk and credit related types
export interface RiskFactor {
  /** Factor name */
  name: string;
  /** Factor weight */
  weight: number;
  /** Impact on risk score */
  impact: 'positive' | 'negative' | 'neutral';
  /** Description */
  description: string;
}

export interface Eligibility {
  /** Whether eligible */
  eligible: boolean;
  /** Eligibility score */
  score: number;
  /** Factors affecting eligibility */
  factors: EligibilityFactor[];
  /** Required actions to maintain eligibility */
  requirements: string[];
}

export interface Creditworthiness {
  /** Creditworthiness level */
  level: 'excellent' | 'good' | 'fair' | 'poor';
  /** Credit limit recommended */
  limit: number;
  /** Interest rate applied */
  interestRate: number;
  /** Terms offered */
  terms: string[];
  /** Risk category */
  riskCategory: 'low' | 'medium' | 'high';
}

export interface CreditMetrics {
  /** Debt-to-income ratio (ZK proof) */
  debtToIncomeRatio: number;
  /** Credit utilization */
  creditUtilization: number;
  /** Payment history consistency */
  paymentConsistency: number;
  /** Credit age */
  creditAge: number;
  /** Recent credit activity */
  activityLevel: number;
}

export interface EligibilityFactor {
  /** Factor name */
  name: string;
  /** Factor impact */
  impact: 'positive' | 'negative' | 'neutral';
  /** Factor score */
  score: number;
  /** Description */
  description: string;
}
