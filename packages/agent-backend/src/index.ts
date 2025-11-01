/**
 * ZKredit Agent Backend - Main Export Module
 * 
 * This module serves as the main entry point for the ZKredit agent backend.
 * It exports all agents, services, types, and utilities needed for the
 * privacy-preserving credit assessment and remittance system.
 */

// Export all types
export * from './types/zk-types';
export * from './types/agent-types';


/**
 * Default configuration for local development
 */
export const DEFAULT_CONFIG = {
  system: {
    environment: 'development',
    logLevel: 'info' as const,
    maxConcurrentUsers: 1000,
    requestTimeout: 30000,
  },
  agents: {
    workers: {
      maxConcurrency: 50,
      timeout: 30000,
      retryAttempts: 3,
    },
    credit: {
      maxConcurrency: 25,
      timeout: 60000,
      minimumConfidence: 0.8,
    },
    remittance: {
      maxConcurrency: 100,
      timeout: 45000,
      optimizeRoutes: true,
    },
    receiver: {
      maxConcurrency: 200,
      timeout: 20000,
      automaticReceipt: true,
    },
  },
  zkp: {
    circuitPath: './circuits',
    proofTimeout: 120000,
    verificationTimeout: 30000,
  },
  network: {
    rpcUrl: process.env.RPC_URL || 'http://localhost:8545',
    chainId: process.env.CHAIN_ID || '1337',
    contractAddresses: {
      zkCreditVerifier: process.env.ZK_CREDIT_VERIFIER_ADDRESS || '0x0000000000000000000000000000000000000000',
      erc8004Registry: process.env.ERC8004_REGISTRY_ADDRESS || '0x0000000000000000000000000000000000000000',
    },
  },
} as const;

export type Config = typeof DEFAULT_CONFIG;
