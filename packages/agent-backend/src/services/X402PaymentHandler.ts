/**
 * X402 Payment Handler Implementation
 * Handles X402 payment protocol for fee processing and payment routing
 * Supports both traditional payments and ZK-based privacy-preserving payments
 */

import { HCSAuditLogger } from './HCSAuditLogger';

export interface PaymentRequest {
  /** Unique payment request identifier */
  id: string;
  /** Amount to be paid */
  amount: number;
  /** Payment currency (USD, EUR, etc.) */
  currency: string;
  /** Recipient address or identifier */
  recipient: string;
  /** Payment purpose/description */
  purpose: string;
  /** Optional ZK proof for privacy-preserving payments */
  zkProof?: {
    proof: string;
    publicSignals: string[];
    proofId: string;
  };
  /** Payment routing preferences */
  routing?: {
    priority: 'low' | 'medium' | 'high';
    preferredChains: string[];
    feePreferences: {
      maxFee: number;
      feeCurrency: string;
    };
  };
}

export interface PaymentResult {
  /** Payment result status */
  status: 'completed' | 'pending' | 'failed' | 'cancelled';
  /** Transaction hash if successful */
  txHash?: string;
  /** Payment processing fees */
  fees: {
    networkFee: number;
    serviceFee: number;
    totalFee: number;
  };
  /** Payment completion timestamp */
  timestamp: number;
  /** Optional error details if failed */
  error?: string;
  /** Payment completion proof */
  completionProof?: string;
}

export interface X402Config {
  /** Enable/disable X402 payment processing */
  enabled: boolean;
  /** Default fee percentage */
  defaultFeePercentage: number;
  /** Minimum payment amount */
  minPaymentAmount: number;
  /** Maximum payment amount */
  maxPaymentAmount: number;
  /** Supported networks/chains */
  supportedNetworks: string[];
  /** Fee collection address */
  feeCollectionAddress: string;
  /** Payment timeout in seconds */
  paymentTimeout: number;
}

/**
 * X402 Payment Handler Service
 * Handles payment processing using X402 protocol
 */
export class X402PaymentHandler {
  private config: X402Config;
  private auditLogger: HCSAuditLogger | null;
  private pendingPayments: Map<string, PaymentRequest>;
  private paymentHistory: Map<string, PaymentResult>;

  constructor(config: X402Config, auditLogger?: HCSAuditLogger) {
    this.config = config;
    this.auditLogger = auditLogger || null;
    this.pendingPayments = new Map();
    this.paymentHistory = new Map();
    
    if (this.config.enabled) {
      console.log('X402 Payment Handler initialized');
    }
  }

  /**
   * Process a payment request
   */
  async processPayment(request: PaymentRequest): Promise<PaymentResult> {
    if (!this.config.enabled) {
      throw new Error('X402 payments are disabled');
    }

    try {
      console.log(`Processing X402 payment ${request.id}: ${request.amount} ${request.currency}`);

      // Validate payment request
      this.validatePaymentRequest(request);

      // Calculate fees
      const fees = await this.calculateFees(request);

      // Log payment initiation
      if (this.auditLogger) {
        await this.auditLogger.logTransaction(
          'X402PaymentHandler',
          request.id,
          'payment_initiated',
          {
            amount: request.amount,
            currency: request.currency,
            recipient: request.recipient,
            fees
          }
        );
      }

      // Process payment based on type
      let result: PaymentResult;
      if (request.zkProof) {
        result = await this.processZKPayment(request, fees);
      } else {
        result = await this.processStandardPayment(request, fees);
      }

      // Store result
      this.paymentHistory.set(request.id, result);

      // Log completion
      if (this.auditLogger) {
        await this.auditLogger.logTransaction(
          'X402PaymentHandler',
          result.txHash || request.id,
          'payment_completed',
          {
            requestId: request.id,
            status: result.status,
            fees
          }
        );
      }

      return result;
    } catch (error) {
      const errorResult: PaymentResult = {
        status: 'failed',
        timestamp: Date.now(),
        fees: { networkFee: 0, serviceFee: 0, totalFee: 0 },
        error: error instanceof Error ? error.message : 'Unknown error'
      };

      // Log error
      if (this.auditLogger) {
        await this.auditLogger.error(
          'X402PaymentHandler',
          'payment_failed',
          error as Error,
          { requestId: request.id }
        );
      }

      return errorResult;
    }
  }

  /**
   * Validate payment request
   */
  private validatePaymentRequest(request: PaymentRequest): void {
    // Amount validation
    if (request.amount <= 0) {
      throw new Error('Payment amount must be positive');
    }
    if (request.amount < this.config.minPaymentAmount) {
      throw new Error(`Payment amount below minimum ${this.config.minPaymentAmount}`);
    }
    if (request.amount > this.config.maxPaymentAmount) {
      throw new Error(`Payment amount above maximum ${this.config.maxPaymentAmount}`);
    }

    // Recipient validation
    if (!request.recipient) {
      throw new Error('Recipient is required');
    }

    // Currency validation
    if (!request.currency || request.currency.length !== 3) {
      throw new Error('Invalid currency code');
    }

    // ZK proof validation if present
    if (request.zkProof) {
      if (!request.zkProof.proof || !request.zkProof.publicSignals || !request.zkProof.proofId) {
        throw new Error('Incomplete ZK proof data');
      }
    }

    // Routing validation if present
    if (request.routing) {
      if (request.routing.feePreferences.maxFee < 0) {
        throw new Error('Invalid fee preferences');
      }
      if (!this.config.supportedNetworks.includes(request.routing.feePreferences.feeCurrency)) {
        throw new Error('Unsupported fee currency');
      }
    }
  }

  /**
   * Calculate payment fees
   */
  private async calculateFees(request: PaymentRequest): Promise<PaymentResult['fees']> {
    const baseFee = request.amount * (this.config.defaultFeePercentage / 100);
    const networkFee = Math.max(baseFee * 0.3, 0.01); // 30% of service fee
    const serviceFee = Math.max(baseFee * 0.7, 0.01); // 70% of service fee
    const totalFee = Math.max(networkFee + serviceFee, 0.01);

    // Apply routing preferences if present
    let finalNetworkFee = networkFee;
    let finalServiceFee = serviceFee;
    let finalTotalFee = totalFee;

    if (request.routing && request.routing.feePreferences.maxFee > 0) {
      if (finalTotalFee > request.routing.feePreferences.maxFee) {
        // Scale fees proportionally to fit within maxFee
        const scale = request.routing.feePreferences.maxFee / finalTotalFee;
        finalNetworkFee = Math.max(0.005, networkFee * scale);
        finalServiceFee = Math.max(0.005, serviceFee * scale);
        finalTotalFee = finalNetworkFee + finalServiceFee;
      }
    }

    return {
      networkFee: Math.round(finalNetworkFee * 100) / 100,
      serviceFee: Math.round(finalServiceFee * 100) / 100,
      totalFee: Math.round(finalTotalFee * 100) / 100
    };
  }

  /**
   * Process standard payment
   */
  private async processStandardPayment(request: PaymentRequest, fees: PaymentResult['fees']): Promise<PaymentResult> {
    console.log(`Processing standard payment ${request.id}`);

    // Simulate payment processing time
    await new Promise(resolve => setTimeout(resolve, 500 + Math.random() * 1000));

    // Simulate occasional payment failures (for testing)
    if (Math.random() < 0.05) { // 5% failure rate
      return {
        status: 'failed',
        timestamp: Date.now(),
        fees,
        error: 'Payment processing failed'
      };
    }

    // Generate transaction hash
    const txHash = this.generateTransactionHash(request);

    return {
      status: 'completed',
      txHash,
      fees,
      timestamp: Date.now(),
      completionProof: this.generateCompletionProof(request, txHash)
    };
  }

  /**
   * Process ZK-based privacy-preserving payment
   */
  private async processZKPayment(request: PaymentRequest, fees: PaymentResult['fees']): Promise<PaymentResult> {
    console.log(`Processing ZK payment ${request.id} with proof verification`);

    if (!request.zkProof) {
      throw new Error('ZK proof missing for ZK payment');
    }

    try {
      // Verify ZK proof (in a real implementation, this would verify the proof)
      await this.verifyZKProof(request.zkProof);

      // Simulate ZK payment processing time (slightly longer due to verification)
      await new Promise(resolve => setTimeout(resolve, 800 + Math.random() * 1200));

      // Generate transaction hash
      const txHash = this.generateTransactionHash(request, true);

      return {
        status: 'completed',
        txHash,
        fees,
        timestamp: Date.now(),
        completionProof: this.generateZKCompletionProof(request, txHash)
      };
    } catch (error) {
      return {
        status: 'failed',
        timestamp: Date.now(),
        fees,
        error: error instanceof Error ? error.message : 'ZK proof verification failed'
      };
    }
  }

  /**
   * Verify ZK proof (simulation for development)
   */
  private async verifyZKProof(zkProof: PaymentRequest['zkProof']): Promise<void> {
    // Simulate proof verification delay
    await new Promise(resolve => setTimeout(resolve, 200 + Math.random() * 300));

    // Simulate proof validation
    if (!zkProof || !zkProof.proof || !zkProof.publicSignals || !zkProof.proofId) {
      throw new Error('Invalid ZK proof structure');
    }

    // Simulate occasional proof verification failures (for testing)
    if (Math.random() < 0.1) { // 10% failure rate
      throw new Error('ZK proof verification failed');
    }

    console.log(`ZK proof verified: ${zkProof.proofId}`);
  }

  /**
   * Generate transaction hash
   */
  private generateTransactionHash(request: PaymentRequest, isZK: boolean = false): string {
    const data = `${request.id}${request.amount}${request.currency}${request.recipient}${isZK ? 'zk' : 'std'}${Date.now()}`;
    const hash = this.simpleHash(data);
    return `0x${hash}`;
  }

  /**
   * Generate completion proof
   */
  private generateCompletionProof(request: PaymentRequest, txHash: string): string {
    const data = `${request.id}${txHash}${Date.now()}completed`;
    return `comp_${this.simpleHash(data)}`;
  }

  /**
   * Generate ZK completion proof
   */
  private generateZKCompletionProof(request: PaymentRequest, txHash: string): string {
    const data = `${request.id}${txHash}${Date.now()}zkcompleted${request.zkProof?.proofId || ''}`;
    return `zkcomp_${this.simpleHash(data)}`;
  }

  /**
   * Simple hash function for development
   */
  private simpleHash(data: string): string {
    let hash = 0;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash).toString(16);
  }

  /**
   * Get payment status
   */
  getPaymentStatus(paymentId: string): PaymentResult | null {
    return this.paymentHistory.get(paymentId) || this.pendingPayments.get(paymentId) as any || null;
  }

  /**
   * Get payment statistics
   */
  getPaymentStats(): {
    totalProcessed: number;
    totalFeesCollected: number;
    successRate: number;
    averageProcessingTime: number;
  } {
    const results = Array.from(this.paymentHistory.values());
    const totalProcessed = results.length;
    
    if (totalProcessed === 0) {
      return {
        totalProcessed: 0,
        totalFeesCollected: 0,
        successRate: 0,
        averageProcessingTime: 0
      };
    }

    const successful = results.filter(r => r.status === 'completed').length;
    const totalFees = results.reduce((sum, r) => sum + r.fees.totalFee, 0);
    
    let totalProcessingTime = 0;
    // Calculate processing time from payment creation to completion
    // This is a simplified calculation

    return {
      totalProcessed,
      totalFeesCollected: Math.round(totalFees * 100) / 100,
      successRate: Math.round((successful / totalProcessed) * 100 * 100) / 100,
      averageProcessingTime: Math.round((totalProcessingTime / totalProcessed) * 100) / 100
    };
  }

  /**
   * Get supported networks
   */
  getSupportedNetworks(): string[] {
    return [...this.config.supportedNetworks];
  }

  /**
   * Get configuration
   */
  getConfig(): Partial<X402Config> {
    return {
      enabled: this.config.enabled,
      supportedNetworks: this.config.supportedNetworks,
      minPaymentAmount: this.config.minPaymentAmount,
      maxPaymentAmount: this.config.maxPaymentAmount,
      defaultFeePercentage: this.config.defaultFeePercentage
    };
  }
}

export default X402PaymentHandler;
