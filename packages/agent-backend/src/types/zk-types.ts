/**
 * Zero-Knowledge Types for ZKredit System
 * Defines all ZK proof structures and verification interfaces
 */

export interface ZKProof {
  /** Unique identifier for this proof */
  proofId: string;
  /** The actual proof data (circuit-specific) */
  proof: string;
  /** Public inputs used for verification */
  publicSignals: string[];
  /** Verification result */
  verified: boolean;
  /** Verification timestamp */
  timestamp: number;
  /** Type of proof (income, credit, collateral, etc.) */
  proofType: ZKProofType;
  /** Verification key reference */
  verificationKeyId?: string;
}

export interface ZKIdentity {
  /** Unique identity identifier */
  id: string;
  /** User's public key for verification */
  publicKey: string;
  /** ZK proofs associated with this identity */
  proofs: ZKProof[];
  /** Verification level achieved */
  verificationLevel: VerificationLevel;
  /** Creation timestamp */
  createdAt: number;
  /** Last update timestamp */
  updatedAt: number;
}

export interface ZKAttributes {
  /** Type of ZK proof to generate */
  type: ZKProofType;
  /** User data to generate proof from */
  userData: UserData;
  /** Verification level required */
  verificationLevel: VerificationLevel;
  /** Additional verification parameters */
  params?: Record<string, unknown>;
}

export interface UserData {
  /** User's first name */
  firstName: string;
  /** User's last name */
  lastName: string;
  /** User's email (for notifications) */
  email: string;
  /** Country of residence */
  country: string;
  /** Employment status */
  employment?: string;
  /** Monthly income amount */
  monthlyIncome: number;
  /** Income currency */
  currency: string;
  /** Loan duration in months */
  duration?: number;
  /** Credit score (if available) */
  creditScore?: number;
  /** Collateral value */
  collateralValue?: number;
  /** KYC level */
  kycLevel: KYCLevel;
}

export interface ZKIncomeProof {
  /** Income amount range */
  incomeRange: {
    min: number;
    max: number;
  };
  /** Income currency */
  currency: string;
  /** Whether the income is stable */
  isStable: boolean;
  /** Proof type (range proof) */
  proofType: 'range';
  /** Commitment value */
  commitment: string;
}

export interface ZKCreditProof {
  /** Credit score range (non-revealing) */
  creditRange: {
    min: number;
    max: number;
  };
  /** Whether credit history is clean */
  isClean: boolean;
  /** Default history (ZK proof) */
  hasDefaults: boolean;
  /** Current credit obligations */
  totalObligations: number;
  /** Monthly payment capacity */
  monthlyCapacity: number;
}

export interface ZKCollateralProof {
  /** Collateral type */
  collateralType: string;
  /** Estimated collateral value range */
  collateralRange: {
    min: number;
    max: number;
  };
  /** Collateral currency */
  currency: string;
  /** LTV (Loan-to-Value) ratio range */
  ltvrange: {
    min: number;
    max: number;
  };
  /** Ownership proof */
  ownershipProven: boolean;
  /** No liens on collateral */
  noLiens: boolean;
}

export interface ZKComplianceProof {
  /** Compliance check status */
  status: 'verified' | 'suspended' | 'rejected';
  /** Regulatory compliance level */
  complianceLevel: 'basic' | 'enhanced' | 'strict';
  /** Risk assessment result */
  riskRating: 'low' | 'medium' | 'high';
  /** Due diligence status */
  dueDiligenceCompleted: boolean;
}

export interface ZKVerificationResult {
  /** Verification success */
  verified: boolean;
  /** Verification time */
  timestamp: number;
  /** Any error messages */
  error?: string;
  /** Verifier information */
  verifierId: string;
  /** Gas used for verification */
  gasUsed?: number;
  /** Transaction hash (if on-chain) */
  txHash?: string;
}

export interface ZKApplication {
  /** Application ID */
  id: string;
  /** User making the application */
  userId: string;
  /** Proofs provided */
  proofs: ZKProof[];
  /** Application type */
  type: ApplicationType;
  /** Application status */
  status: ApplicationStatus;
  /** Creation timestamp */
  createdAt: number;
  /** Last update timestamp */
  updatedAt: number;
}

// Enums
export enum ZKProofType {
  INCOME_VERIFICATION = 'income_verification',
  CREDIT_HISTORY_VERIFICATION = 'credit_history_verification',
  COLLATERAL_VERIFICATION = 'collateral_verification',
  COMPLIANCE_VERIFICATION = 'compliance_verification',
  IDENTITY_VERIFICATION = 'identity_verification',
  PAYMENT_PRIVACY = 'payment_privacy',
  WORKFLOW_COMPLETED = 'workflow_completed'
}

export enum VerificationLevel {
  BASIC = 'basic',
  ENHANCED = 'enhanced',
  PREMIUM = 'premium',
  ENTERPRISE = 'enterprise'
}

export enum KYCLevel {
  NO_KYC = 'no_kyc',
  BASIC = 'basic',
  ENHANCED = 'enhanced',
  STRICT = 'strict'
}

export enum ApplicationType {
  LOAN_APPLICATION = 'loan_application',
  REMITTANCE_REQUEST = 'remittance_request',
  CREDIT_CHECK = 'credit_check',
  COMPLIANCE_CHECK = 'compliance_check'
}

export enum ApplicationStatus {
  PENDING = 'pending',
  UNDER_REVIEW = 'under_review',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  CANCELLED = 'cancelled',
  COMPLETED = 'completed'
}

export interface ProofGenerationOptions {
  /** Whether to include commitment */
  commitment: boolean;
  /** Additional proof parameters */
  params?: Record<string, unknown>;
  /** Circuit to use */
  circuit?: string;
}

export interface ProofVerificationOptions {
  /** Verification key to use */
  verificationKey?: string;
  /** On-chain verification */
  onChain?: boolean;
  /** Allow cached verification */
  allowCached?: boolean;
}

export interface ZKWallet {
  /** Wallet address */
  address: string;
  /** Public key */
  publicKey: string;
  /** ZK identity */
  identity: ZKIdentity;
  /** Linked proofs */
  proofs: ZKProof[];
}
