# 🤖 Agent System Design Guide

This comprehensive guide covers the design and implementation of the multi-agent system in ZKredit, including agent responsibilities, communication patterns, and architectural decisions.

## 📋 Table of Contents

- [Agent Architecture Overview](#agent-architecture-overview)
- [Agent Types and Responsibilities](#agent-types-and-responsibilities)
- [Communication Patterns](#communication-patterns)
- [State Management](#state-management)
- [Agent Coordination](#agent-coordination)
- [Error Handling and Recovery](#error-handling-and-recovery)
- [Monitoring and Observability](#monitoring-and-observability)
- [Testing Strategies](#testing-strategies)
- [Deployment Patterns](#deployment-patterns)

## 🎯 Agent Architecture Overview

The ZKredit system employs a multi-agent architecture where each agent has specialized responsibilities. This design pattern promotes:

- **Separation of Concerns**: Each agent handles a specific domain
- **Scalability**: Agents can be scaled independently
- **Fault Tolerance**: Agent failures are isolated
- **Maintainability**: Clear boundaries between components
- **Extensibility**: New agents can be added easily

### High-Level Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      Agent System                                 │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                    Agent Manager                           │ │
│  │                (Coordination & Discovery)                  │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────┬───────────────┬─────────────────────┐          │
│  │ WorkerAgent │ CreditAgent │ RemittanceAgent  │          │
│  │             │               │                   │          │
│  │Onboarding │ Assessment  │ Payment           │          │
│  │ZK Proofs    │ Verification│ Processing       │          │
│  └─────────────┴───────────────┴─────────────────────┘          │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│                   Service Layer                                │
│  ┌──────────────┬─────────────────┬──────────────────────┐      │
│  │ ZK Proof    │ Payment        │ Audit & Log         │      │
│  │ Service     │ Service        │ Service             │      │
│  └──────────────┴─────────────────┴──────────────────────┘      │
└────────────────────────────────────────────────────────────────┘
```

## 👥 Agent Types and Responsibilities

### 1. WorkerAgent

**Purpose**: User onboarding, identity management, and ZK proof generation

**Key Responsibilities**:
- Identity creation and verification
- Document processing and validation
- ZK proof generation for user credentials
- Application submission coordination
- User status tracking

**Core Methods**:
```typescript
class WorkerAgent {
    async createIdentity(userData: UserData): Promise<Identity>
    async generateZKProof(attributes: ZKAttributes): Promise<ZKProof>
    async submitApplication(application: LoanApplication): Promise<ApplicationResult>
    async updateIdentity(identityId: string, updates: Partial<UserData>): Promise<Identity>
    async getApplicationStatus(applicationId: string): Promise<ApplicationStatus>
}
```

**State Management**:
```typescript
interface WorkerAgentState {
    // Current user applications
    activeApplications: Map<string, Application>;
    
    // Identity registry
    identities: Map<string, Identity>;
    
    // Pending verification tasks
    verificationQueue: Queue<VerificationTask>;
    
    // ZK proof cache
    proofCache: LRUCache<ZKProof>;
}
```

### 2. CreditAssessmentAgent

**Purpose**: Credit analysis, risk assessment, and loan decision making

**Key Responsibilities**:
- ZK proof validation and verification
- Credit score calculation based on verified attributes
- Risk assessment and loan approval decision
- Fraud detection and prevention
- Compliance checking and reporting

**Core Methods**:
```typescript
class CreditAssessmentAgent {
    async verifyZKProof(proof: ZKProof): Promise<boolean>
    async calculateCreditScore(attributes: VerifiedAttributes): Promise<CreditScore>
    async assessRisk(creditData: CreditData): Promise<RiskAssessment>
    async approveLoan(application: LoanApplication): Promise<LoanDecision>
    async generateComplianceReport(data: AssessmentData): Promise<ComplianceReport>
}
```

**State Management**:
```typescript
interface CreditAssessmentAgentState {
    // Current assessment queue
    assessments: Map<string, Assessment>;
    
    // Credit scoring models
    scoringModels: Map<string, ScoringModel>;
    
    // Risk parameters
    riskParameters: RiskParameters;
    
    // Assessment history for ML training
    assessmentHistory: Array<CompletedAssessment>;
}
```

### 3. RemittanceAgent

**Purpose**: Payment processing, routing, and compliance

**Key Responsibilities**:
- Payment route optimization
- Fee calculation and distribution
- Compliance checking and regulatory reporting
- Escrow management and release
- Multi-currency handling

**Core Methods**:
```typescript
class RemittanceAgent {
    async optimizeRoute(remittance: RemittanceRequest): Promise<PaymentRoute>
    async calculateFees(amount: Amount): Promise<FeeStructure>
    async processPayment(payment: Payment): Promise<PaymentResult>
    async manageEscrow(escrow: Escrow): Promise<EscrowResult>
    async updateExchangeRates(rates: ExchangeRates): Promise<void>
}
```

**State Management**:
```typescript
interface RemittanceAgentState {
    // Active payments
    activePayments: Map<string, Payment>;
    
    // Payment routes and rates
    paymentRoutes: PaymentRouteEngine;
    
    // Escrow accounts
    escrowAccounts: Map<string, EscrowAccount>;
    
    // Compliance status
    complianceStatus: ComplianceTracker;
}
```

### 4. ReceiverAgent

**Purpose**: Recipient verification and fund distribution

**Key Responsibilities**:
- Recipient identity verification
- Fund availability confirmation
- Transaction completion notification
- Dispute resolution initiation
- Account reconciliation

**Core Methods**:
```typescript
class ReceiverAgent {
    async verifyRecipient(recipient: Recipient): Promise<VerificationResult>
    async confirmFundAvailability(fund: Fund): Promise<FundStatus>
    async completeTransaction(transaction: Transaction): Promise<TransactionResult>
    async initiateDispute(dispute: Dispute): Promise<DisputeResolution>
    async reconcileAccounts(reconciliationData: ReconciliationData): Promise<ReconciliationResult>
}
```

**State Management**:
```typescript
interface ReceiverAgentState {
    // Pending recipients
    pendingRecipients: Map<string, Recipient>;
    
    // Completed transactions
    transactions: Map<string, Transaction>;
    
    // Active disputes
    disputes: Map<string, Dispute>;
    
    // Reconciliation data
    reconciliationQueue: Queue<ReconciliationData>;
}
```

## 🔗 Communication Patterns

### 1. Message Queue Architecture

```typescript
// Base message interface
interface AgentMessage {
    id: string;
    sender: string;
    recipient: string;
    type: MessageType;
    payload: any;
    timestamp: number;
    correlationId?: string;
    replyTo?: string;
}

// Message types
enum MessageType {
    TASK_ASSIGNMENT = 'TASK_ASSIGNMENT',
    TASK_COMPLETION = 'TASK_COMPLETION',
    AGENT_STATUS = 'AGENT_STATUS',
    VERIFICATION_REQUEST = 'VERIFICATION_REQUEST',
    VERIFICATION_RESPONSE = 'VERIFICATION_RESPONSE',
    PAYMENT_REQUEST = 'PAYMENT_REQUEST',
    PAYMENT_STATUS = 'PAYMENT_STATUS',
    COMPLIANCE_ALERT = 'COMPLIANCE_ALERT',
    FRAUD_DETECTION = 'FRAUD_DETECTION'
}

// Agent communication manager
class AgentCommunicationManager {
    private messageQueue: MessageQueue;
    private agentRegistry: AgentRegistry;
    
    async sendMessage(message: AgentMessage): Promise<void>
    async broadcastMessage(message: Omit<AgentMessage, 'recipient'>): Promise<void>
    async receiveMessages(agentId: string): Promise<AgentMessage[]>
    async acknowledgeMessage(messageId: string): Promise<void>
}
```

### 2. Event-Driven Communication

```typescript
// Event system for agent coordination
interface AgentEvent {
    type: EventType;
    source: string;
    timestamp: number;
    data: any;
    metadata?: Record<string, any>;
}

enum EventType {
    AGENT_STARTED = 'AGENT_STARTED',
    AGENT_STOPPED = 'AGENT_STOPPED',
    TASK_SUBMITTED = 'TASK_SUBMITTED',
    TASK_COMPLETED = 'TASK_COMPLETED',
    TASK_FAILED = 'TASK_FAILED',
    STATE_CHANGED = 'STATE_CHANGED',
    ERROR_OCCURRED = 'ERROR_OCCURRED'
}

class AgentEventBus {
    private subscribers: Map<EventType, Array<(event: AgentEvent) => void>>;
    
    publish(event: AgentEvent): void
    subscribe(eventType: EventType, callback: (event: AgentEvent) => void): void
    unsubscribe(eventType: EventType, callback: (event: AgentEvent) => void): void
}
```

### 3. Request-Response Pattern

```typescript
// Request handling
interface AgentRequest {
    id: string;
    requester: string;
    handler: string;
    method: string;
    params: any;
    timeout: number;
    priority: Priority;
}

interface AgentResponse {
    requestId: string;
    status: 'success' | 'error' | 'timeout';
    result?: any;
    error?: Error;
}

class AgentRequestHandler {
    async handleRequest(request: AgentRequest): Promise<AgentResponse>
    async sendRequest(request: AgentRequest): Promise<AgentResponse>
    async cancelRequest(requestId: string): Promise<void>
}
```

## 📊 State Management

### 1. Distributed State Architecture

```typescript
// Distributed state key-value store
interface DistributedState {
    get(key: string): Promise<any>
    set(key: string, value: any): Promise<void>
    delete(key: string): Promise<void>
    exists(key: string): Promise<boolean>
    watch(key: string, callback: (value: any) => void): () => void
}

class AgentStateManager {
    private distributedState: DistributedState;
    private localCache: Map<string, any>;
    private stateObservers: Array<(state: AgentState) => void>;
    
    constructor(private agentId: string) {
        this.localCache = new Map();
        this.stateObservers = [];
    }
    
    async updateState(newProperties: Partial<AgentState>): Promise<void>
    async getState(): Promise<AgentState>
    async subscribeToStateUpdates(callback: (state: AgentState) => void): void
    async syncWithDistributedState(): Promise<void>
}
```

### 2. Event Sourcing for Agent State

```typescript
// Event store for agent state changes
interface AgentEvent {
    id: string;
    type: string;
    aggregateId: string;
    aggregateType: 'Agent' | 'Task' | 'Process';
    timestamp: number;
    data: any;
    metadata?: Record<string, any>;
}

class AgentEventStore {
    private events: Array<AgentEvent> = [];
    
    async appendEvent(event: AgentEvent): Promise<void>
    async getEvents(aggregateId: string): Promise<AgentEvent[]>
    async getSnapshot(aggregateId: string): Promise<any>
    async replayEvents(aggregateId: string): Promise<void>
    
    // State reconstruction
    reconstructState(events: AgentEvent[]): AgentState {
        let state = this.getInitialState();
        
        events.forEach(event => {
            state = this.applyEvent(state, event);
        });
        
        return state;
    }
}
```

## 🤝 Agent Coordination

### 1. Workflow Orchestration

```typescript
// Workflow definition
interface AgentWorkflow {
    id: string;
    name: string;
    steps: WorkflowStep[];
    triggers: WorkflowTrigger[];
    conditions?: WorkflowCondition[];
}

interface WorkflowStep {
    id: string;
    agent: string;
    task: string;
    parameters?: any;
    retries?: number;
    timeout?: number;
    conditions?: WorkflowCondition[];
}

class WorkflowEngine {
    private workflows: Map<string, AgentWorkflow>;
    
    async executeWorkflow(workflowId: string, input: any): Promise<WorkflowExecution>
    async pauseWorkflow(executionId: string): Promise<void>
    async resumeWorkflow(executionId: string): Promise<void>
    async cancelWorkflow(executionId: string): Promise<void>
    async getWorkflowStatus(executionId: string): Promise<WorkflowStatus>
}

// Example loan application workflow
const loanApplicationWorkflow: AgentWorkflow = {
    id: 'loan-application',
    name: 'Loan Application Process',
    triggers: [
        { type: 'manual', handler: 'WorkerAgent.createLoanApplication' }
    ],
    steps: [
        {
            id: 'generate-proof',
            agent: 'WorkerAgent',
            task: 'generateZKProof',
            parameters: { type: 'income_verification' }
        },
        {
            id: 'assess-credit',
            agent: 'CreditAssessmentAgent',
            task: 'assessApplication',
            dependencies: ['generate-proof']
        },
        {
            id: 'process-payment',
            agent: 'RemittanceAgent',
            task: 'processLoanPayment',
            dependencies: ['assess-credit'],
            conditions: [{ field: 'creditDecision', operator: 'equals', value: 'approved' }]
        }
    ]
};
```

### 2. Agent Discovery and Registry

```typescript
// Agent registry for service discovery
interface AgentRegistration {
    id: string;
    type: AgentType;
    capabilities: string[];
    endpoints: string[];
    health: AgentHealth;
    lastHeartbeat: number;
}

interface AgentRegistry {
    register(agent: AgentRegistration): Promise<void>
    unregister(agentId: string): Promise<void>
    discover(capability: string): Promise<AgentRegistration[]>
    getAgent(agentId: string): Promise<AgentRegistration | null>
    updateHealth(agentId: string, health: AgentHealth): Promise<void>
}

class AgentDiscoveryService {
    private registry: AgentRegistry;
    private healthCheckInterval: NodeJS.Timer;
    
    async registerAgent(registration: AgentRegistration): Promise<void>
    async findAgentsWithCapability(capability: string): Promise<AgentRegistration[]>
    async monitorAgentHealth(agentId: string): Promise<void>
    async handleAgentFailure(agentId: string): Promise<void>
}
```

### 3. Load Balancing and Scaling

```typescript
// Agent load balancer
interface AgentLoadBalancer {
    selectAgent(request: AgentRequest): Promise<AgentRegistration>
    updateAgentStatus(agentId: string, load: number): Promise<void>
    getAgentStats(agentId: string): Promise<AgentStats>
}

class RoundRobinLoadBalancer implements AgentLoadBalancer {
    private agents: Array<AgentRegistration> = [];
    private currentIndex = 0;
    
    async selectAgent(request: AgentRequest): Promise<AgentRegistration> {
        if (this.agents.length === 0) {
            throw new Error('No agents available');
        }
        
        const agent = this.agents[this.currentIndex];
        this.currentIndex = (this.currentIndex + 1) % this.agents.length;
        
        return agent;
    }
}

class WeightedLoadBalancer implements AgentLoadBalancer {
    private agents: Array<{ agent: AgentRegistration; weight: number }> = [];
    
    async selectAgent(request: AgentRequest): Promise<AgentRegistration> {
        const totalWeight = this.agents.reduce((sum, a) => sum + a.weight, 0);
        const random = Math.random() * totalWeight;
        
        let currentWeight = 0;
        for (const { agent, weight } of this.agents) {
            currentWeight += weight;
            if (random <= currentWeight) {
                return agent;
            }
        }
        
        return this.agents[0].agent;
    }
}
```

## ⚠️ Error Handling and Recovery

### 1. Agent Error Classification

```typescript
enum AgentErrorType {
    NETWORK_ERROR = 'NETWORK_ERROR',
    VALIDATION_ERROR = 'VALIDATION_ERROR',
    TIMEOUT_ERROR = 'TIMEOUT_ERROR',
    RESOURCE_ERROR = 'RESOURCE_ERROR',
    PERMISSION_ERROR = 'PERMISSION_ERROR',
    BUSINESS_LOGIC_ERROR = 'BUSINESS_LOGIC_ERROR',
    CONFIGURATION_ERROR = 'CONFIGURATION_ERROR',
    UNKNOWN_ERROR = 'UNKNOWN_ERROR'
}

interface AgentError extends Error {
    type: AgentErrorType;
    code: string;
    details?: any;
    retryable: boolean;
    agentId: string;
    timestamp: number;
    correlationId?: string;
}

class AgentErrorHandler {
    async handleError(error: AgentError): Promise<void> {
        this.logger.error('Agent error occurred', {
            error: error.message,
            type: error.type,
            agentId: error.agentId,
            correlationId: error.correlationId,
            timestamp: error.timestamp
        });

        if (error.retryable) {
            await this.scheduleRetry(error);
        } else {
            await this.reportPermanentFailure(error);
        }
    }

    private async scheduleRetry(error: AgentError): Promise<void> {
        const retryDelay = this.calculateRetryDelay(error);
        await this.scheduleTask(error.correlationId, retryDelay);
    }

    private calculateRetryDelay(error: AgentError): number {
        // Exponential backoff with jitter
        const baseDelay = 1000; // 1 second
        const maxDelay = 300000; // 5 minutes
        const attempts = this.getRetryAttempts(error.correlationId);
        const exponentialDelay = baseDelay * Math.pow(2, attempts);
        const jitter = Math.random() * 0.1 * exponentialDelay;
        
        return Math.min(exponentialDelay + jitter, maxDelay);
    }
}
```

### 2. Circuit Breaker Pattern

```typescript
interface CircuitBreakerState {
    isOpen: boolean;
    failureCount: number;
    lastFailureTime: number;
    successCount: number;
}

class AgentCircuitBreaker {
    private state: CircuitBreakerState;
    private failureThreshold: number;
    private successThreshold: number;
    private timeout: number;
    
    constructor(
        private agentId: string,
        failureThreshold = 5,
        successThreshold = 2,
        timeout = 30000 // 30 seconds
    ) {
        this.state = {
            isOpen: false,
            failureCount: 0,
            lastFailureTime: 0,
            successCount: 0
        };
        this.failureThreshold = failureThreshold;
        this.successThreshold = successThreshold;
        this.timeout = timeout;
    }
    
    async execute<T>(operation: () => Promise<T>): Promise<T> {
        if (this.state.isOpen) {
            if (Date.now() - this.state.lastFailureTime > this.timeout) {
                this.state.isOpen = false;
                this.state.failureCount = 0;
            } else {
                throw new Error('Circuit breaker is open');
            }
        }
        
        try {
            const result = await operation();
            this.onSuccess();
            return result;
        } catch (error) {
            this.onFailure();
            throw error;
        }
    }
    
    private onSuccess(): void {
        this.state.successCount++;
        this.state.failureCount = 0;
        
        if (this.state.successCount >= this.successThreshold) {
            this.state.isOpen = false;
        }
    }
    
    private onFailure(): void {
        this.state.failureCount++;
        this.state.lastFailureTime = Date.now();
        
        if (this.state.failureCount >= this.failureThreshold) {
            this.state.isOpen = true;
            this.logger.warn('Circuit breaker opened', {
                agentId: this.agentId,
                failureCount: this.state.failureCount,
                lastFailureTime: this.state.lastFailureTime
            });
        }
    }
}
```

### 3. Agent Recovery Strategies

```typescript
interface RecoveryStrategy {
    name: string;
    canHandle(error: AgentError): boolean;
    execute(error: AgentError): Promise<void>;
}

class AgentRecoveryService {
    private recoveryStrategies: RecoveryStrategy[];
    private recoveryAttempts: Map<string, RecoveryAttempt>;

    constructor(private logger: Logger) {
        this.recoveryStrategies = [
            new RetryStrategy(),
            new FailoverStrategy(),
            new DegradationStrategy(),
            new ManualRecoveryStrategy()
        ];
        this.recoveryAttempts = new Map();
    }

    async attemptRecovery(error: AgentError): Promise<boolean> {
        const attempts = this.recoveryAttempts.get(error.correlationId) || { count: 0, lastAttempt: 0 };
        
        if (Date.now() - attempts.lastAttempt < this.getRecoveryDelay(attempts.count)) {
            return false; // Too soon for another attempt
        }

        for (const strategy of this.recoveryStrategies) {
            if (strategy.canHandle(error)) {
                try {
                    await strategy.execute(error);
                    this.recoveryAttempts.delete(error.correlationId);
                    return true;
                } catch (recoveryError) {
                    this.logger.error('Recovery strategy failed', {
                        strategy: strategy.name,
                        originalError: error.message,
                        recoveryError: recoveryError.message
                    });
                    
                    attempts.count++;
                    attempts.lastAttempt = Date.now();
                    break;
                }
            }
        }

        this.recoveryAttempts.set(error.correlationId, attempts);
        return false;
    }

    private getRecoveryDelay(attemptCount: number): number {
        // Exponential backoff for recovery attempts
        return Math.min(1000 * Math.pow(2, attemptCount), 300000); // Max 5 minutes
    }
}
```

## 📊 Monitoring and Observability

### 1. Agent Metrics

```typescript
// Agent performance metrics
interface AgentMetrics {
    tasksCompleted: number;
    tasksFailed: number;
    averageProcessingTime: number;
    currentLoad: number;
    healthScore: number;
    responseTime: number;
}

class AgentMetricsCollector {
    private metrics: Map<string, AgentMetrics> = new Map();
    
    collectMetrics(agentId: string): AgentMetrics {
        const agent = this.getAgent(agentId);
        const metrics: AgentMetrics = {
            tasksCompleted: agent.getCompletedTaskCount(),
            tasksFailed: agent.getFailedTaskCount(),
            averageProcessingTime: agent.getAverageProcessingTime(),
            currentLoad: agent.getCurrentLoad(),
            healthScore: this.calculateHealthScore(agent),
            responseTime: agent.getAverageResponseTime()
        };
        
        this.metrics.set(agentId, metrics);
        return metrics;
    }

    publishMetrics(): void {
        this.metrics.forEach((metrics, agentId) => {
            this.telemetry.gauge('agent.health.score', metrics.healthScore, { agentId });
            this.telemetry.gauge('agent.current.load', metrics.currentLoad, { agentId });
            this.telemetry.histogram('agent.processing.time', metrics.averageProcessingTime, { agentId });
            this.telemetry.histogram('agent.response.time', metrics.responseTime, { agentId });
        });
    }

    private calculateHealthScore(agent: Agent): number {
        const successRate = agent.getCompletedTaskCount() / 
            (agent.getCompletedTaskCount() + agent.getFailedTaskCount());
        const loadFactor = Math.max(0, 1 - agent.getCurrentLoad() / agent.getMaxLoad());
        
        return (successRate * 0.7 + loadFactor * 0.3) * 100;
    }
}
```

### 2. Distributed Tracing

```typescript
// Distributed tracing for agent interactions
interface AgentSpan {
    traceId: string;
    spanId: string;
    parentSpanId?: string;
    agentId: string;
    operation: string;
    startTime: number;
    endTime?: number;
    tags: Record<string, string>;
    logs: Array<{ timestamp: number; message: string; fields?: any }>;
}

class AgentTracer {
    private currentSpans: Map<string, AgentSpan> = new Map();
    
    startSpan(agentId: string, operation: string, parentSpanId?: string): string {
        const spanId = this.generateSpanId();
        const span: AgentSpan = {
            traceId: this.getCurrentTraceId(),
            spanId,
            parentSpanId,
            agentId,
            operation,
            startTime: Date.now(),
            tags: {},
            logs: []
        };
        
        this.currentSpans.set(spanId, span);
        return spanId;
    }
    
    endSpan(spanId: string): void {
        const span = this.currentSpans.get(spanId);
        if (span) {
            span.endTime = Date.now();
            this.tracerReporter.reportSpan(span);
            this.currentSpans.delete(spanId);
        }
    }
    
    addTag(spanId: string, key: string, value: string): void {
        const span = this.currentSpans.get(spanId);
        if (span) {
            span.tags[key] = value;
        }
    }
    
    addLog(spanId: string, message: string, fields?: any): void {
        const span = this.currentSpans.get(spanId);
        if (span) {
            span.logs.push({
                timestamp: Date.now(),
                message,
                fields
            });
        }
    }
}
```

### 3. Real-time Monitoring Dashboard

```typescript
// Real-time agent monitoring dashboard
interface AgentDashboardData {
    agents: Array<{
        id: string;
        type: string;
        status: 'healthy' | 'degraded' | 'unhealthy' | 'offline';
        tasks: { total: number; active: number; failed: number };
        performance: { avgResponseTime: number; throughput: number };
    }>;
    workflows: Array<{
        id: string;
        status: 'running' | 'completed' | 'failed' | 'cancelled';
        progress: number;
        agents: string[];
    }>;
    alerts: Array<{
        id: string;
        severity: 'info' | 'warning' | 'error' | 'critical';
        message: string;
        source: string;
        timestamp: number;
    }>;
}

class AgentDashboard {
    private dashboardData: AgentDashboardData;
    private subscribers: Array<(data: AgentDashboardData) => void> = [];
    
    async updateDashboard(): Promise<void> {
        const agents = await this.getAllAgents();
        const workflows = await this.getActiveWorkflows();
        const alerts = await this.getRecentAlerts();
        
        this.dashboardData = {
            agents: agents.map(agent => ({
                id: agent.id,
                type: agent.type,
                status: agent.getHealthStatus(),
                tasks: agent.getTaskStatistics(),
                performance: agent.getPerformanceMetrics()
            })),
            workflows: workflows.map(workflow => ({
                id: workflow.id,
                status: workflow.status,
                progress: workflow.getProgress(),
                agents: workflow.getAssignedAgents()
            })),
            alerts
        };
        
        this.notifySubscribers();
    }
    
    subscribe(callback: (data: AgentDashboardData) => void): () => void {
        this.subscribers.push(callback);
        return () => {
            const index = this.subscribers.indexOf(callback);
            if (index > -1) {
                this.subscribers.splice(index, 1);
            }
        };
    }
    
    private notifySubscribers(): void {
        this.subscribers.forEach(callback => callback(this.dashboardData));
    }
}
```

## 🧪 Testing Strategies

### 1. Unit Testing Agent Behaviors

```typescript
// worker-agent.test.ts
describe('WorkerAgent', () => {
    let workerAgent: WorkerAgent;
    let mockZKService: jest.Mocked<ZKProofService>;
    let mockRegistry: jest.Mocked<AgentRegistry>;

    beforeEach(() => {
        mockZKService = {
            generateProof: jest.fn(),
            verifyProof: jest.fn()
        } as any;
        
        mockRegistry = {
            register: jest.fn(),
            discover: jest.fn()
        } as any;

        workerAgent = new WorkerAgent(mockZKService, mockRegistry);
    });

    describe('createIdentity', () => {
        test('should create valid identity with all required fields', async () => {
            const userData = generateValidUserData();
            const identity = await workerAgent.createIdentity(userData);

            expect(identity).toBeDefined();
            expect(identity.id).toBeDefined();
            expect(identity.userData).toEqual(userData);
            expect(identity.createdAt).toBeInstanceOf(Date);
            
            expect(mockRegistry.register).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'WorkerAgent',
                    id: workerAgent.getId()
                })
            );
        });

        test('should reject identity with invalid user data', async () => {
            const invalidUserData = generateInvalidUserData();

            await expect(workerAgent.createIdentity(invalidUserData))
                .rejects.toThrow('Invalid user data provided');
        });

        test('should generate ZK proof for user credentials', async () => {
            const userData = generateValidUserData();
            const mockProof = generateMockZKProof();
            mockZKService.generateProof.mockResolvedValue(mockProof);

            const identity = await workerAgent.createIdentity(userData);

            expect(mockZKService.generateProof).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'identity_verification',
                    userData
                })
            );
            expect(identity.zkProof).toEqual(mockProof);
        });
    });

    describe('generateZKProof', () => {
        test('should generate valid ZK proof for income verification', async () => {
            const userData = generateValidUserData();
            const mockProof = generateMockZKProof();
            mockZKService.generateProof.mockResolvedValue(mockProof);

            const proof = await workerAgent.generateZKProof({
                type: 'income_verification',
                userData,
                range: { min: 30000, max: 150000 }
            });

            expect(proof).toEqual(mockProof);
            expect(proof.circuitType).toBe('income_verification');
            expect(proof.valid).toBe(true);
        });

        test('should cache frequently requested proofs', async () => {
            const userData = generateValidUserData();
            const mockProof = generateMockZKProof();
            mockZKService.generateProof.mockResolvedValue(mockProof);

            // First call
            await workerAgent.generateZKProof({ type: 'identity', userData });
            // Second call should use cache
            await workerAgent.generateZKProof({ type: 'identity', userData });

            expect(mockZKService.generateProof).toHaveBeenCalledTimes(1);
        });
    });
});
```

### 2. Integration Testing with Service Dependencies

```typescript
// integration/agent-integration.test.ts
describe('Agent Integration Tests', () => {
    let workerAgent: WorkerAgent;
    let creditAgent: CreditAssessmentAgent;
    let remittanceAgent: RemittanceAgent;
    let testDb: TestDatabase;
    let messageQueue: TestMessageQueue;

    beforeAll(async () => {
        // Initialize test infrastructure
        testDb = await createTestDatabase();
        messageQueue = await createTestMessageQueue();
        
        // Initialize agents
        workerAgent = new WorkerAgent(
            new ZKProofService(testDb),
            new AgentRegistry(testDb),
            messageQueue
        );
        
        creditAgent = new CreditAssessmentAgent(messageQueue);
        remittanceAgent = new RemittanceAgent(messageQueue);
    });

    afterAll(async () => {
        await testDb.cleanup();
        await messageQueue.cleanup();
    });

    test('should complete full loan application workflow', async () => {
        // Step 1: User submits application
        const userData = generateValidUserData();
        const identity = await workerAgent.createIdentity(userData);

        // Step 2: Generate ZK proofs
        const incomeProof = await workerAgent.generateZKProof({
            type: 'income_verification',
            userData,
            range: { min: 40000, max: 100000 }
        });

        const creditProof = await workerAgent.generateZKProof({
            type: 'credit_verification',
            userData,
            minCreditScore: 650
        });

        expect(incomeProof.valid).toBe(true);
        expect(creditProof.valid).toBe(true);

        // Step 3: Submit application
        const application = await workerAgent.submitApplication({
            identity,
            proofs: { incomeProof, creditProof },
            loanAmount: 25000
        });

        expect(application.id).toBeDefined();
        expect(application.status).toBe('submitted');

        // Step 4: Credit assessment (async process)
        await messageQueue.sendMessage({
            type: 'CREDIT_ASSESSMENT_REQUEST',
            payload: { applicationId: application.id }
        });

        // Wait for processing
        await waitForMessage('CREDIT_ASSESSMENT_RESPONSE', 5000);

        // Step 5: Verify assessment result
        const updatedApplication = await workerAgent.getApplicationStatus(application.id);
        expect(updatedApplication.status).toBe('approved');
        expect(updatedApplication.creditScore).toBeGreaterThanOrEqual(650);
    });

    test('should handle agent failures gracefully', async () => {
        // Simulate agent failure
        await creditAgent.stop();

        // Submit application
        const userData = generateValidUserData();
        const identity = await workerAgent.createIdentity(userData);
        const proof = await workerAgent.generateZKProof({ 
            type: 'income_verification', 
            userData 
        });
        
        const application = await workerAgent.submitApplication({
            identity,
            proofs: { incomeProof: proof },
            loanAmount: 15000
        });

        // The system should queue the request for retry
        const queuedRequests = await messageQueue.getQueuedMessages();
        expect(queuedRequests).toHaveLength(1);
        expect(queuedRequests[0].payload.applicationId).toBe(application.id);

        // Restart agent and verify processing
        await creditAgent.start();
        await waitForMessage('CREDIT_ASSESSMENT_RESPONSE', 10000);

        const processedApplication = await workerAgent.getApplicationStatus(application.id);
        expect(processedApplication.status).toBe('approved');
    });
});
```

### 3. End-to-End Test with Mock ZK Proofs

```typescript
// e2e/zk-integrated-flow.test.ts
describe('ZK-Integrated End-to-End Tests', () => {
    let workerAgent: WorkerAgent;
    let creditAgent: CreditAssessmentAgent;
    let zkProofService: ZKProofService;
    let testUserData: UserData;

    beforeAll(async () => {
        // Initialize full system
        const app = await createTestApplication();
        workerAgent = app.getWorkerAgent();
        creditAgent = app.getCreditAssessmentAgent();
        zkProofService = app.getZKProofService();

        testUserData = generateCompleteTestUser();
    });

    test('should prove income without revealing exact amount', async () => {
        // User provides actual income (private)
        const actualIncome = 75000;
        
        // Generate ZK proof showing income is in range [50000, 150000]
        const incomeProof = await zkProofService.generateZKProof({
            circuit: 'income_verification',
            privateInputs: {
                salary: actualIncome,
                bonus: 0
            },
            publicInputs: {
                min_income: 50000,
                max_income: 150000
            }
        });

        // Credit agent verifies proof without seeing actual income
        const isValid = await creditAgent.verifyZKProof(incomeProof);
        expect(isValid).toBe(true);

        // Verify that credit agent cannot see exact income
        const creditAgentView = await creditAgent.getProofDetails(incomeProof.id);
        expect(creditAgentView.actualIncome).toBeUndefined();
        expect(creditAgentView.incomeRange).toEqual({ min: 50000, max: 150000 });
    });

    test('should prove credit score meets requirements', async () => {
        // User with credit score 720 (private)
        const creditScore = 720;
        
        const creditProof = await zkProofService.generateZKProof({
            circuit: 'credit_history',
            privateInputs: {
                credit_score: creditScore,
                payment_history: 2, // 2 late payments
                debt_ratio: 0.3,
                credit_history_length: 60 // 60 months
            },
            publicInputs: {
                min_credit_score: 700,
                max_delays: 5,
                max_debt_ratio: 0.4,
                min_history_months: 12
            }
        });

        const assessment = await creditAgent.verifyZKProof(creditProof);
        expect(assessment.approved).toBe(true);

        // Verify that actual credit score is not revealed
        const proofDetails = await zkProofService.getProofDetails(creditProof.id);
        expect(proofDetails.actualScore).toBeUndefined();
        expect(proofDetails.scoreThreshold).toBe(700);
        expect(proofDetails.meetsThreshold).toBe(true);
    });
});
```

## 🚀 Deployment Patterns

### 1. Blue-Green Deployment for Agents

```typescript
// deployment/agent-deployment.ts
export enum DeploymentStrategy {
    BLUE_GREEN = 'BLUE_GREEN',
    ROLLING_UPDATE = 'ROLLING_UPDATE',
    CANARY = 'CANARY',
    AB_TEST = 'AB_TEST'
}

class AgentDeploymentManager {
    private deployments: Map<string, AgentDeployment> = new Map();
    private currentVersion: Map<string, string> = new Map();

    async deployAgent(agentDeployment: AgentDeployment): Promise<DeploymentResult> {
        const strategy = this.selectDeploymentStrategy(agentDeployment);
        
        switch (strategy) {
            case DeploymentStrategy.BLUE_GREEN:
                return await this.blueGreenDeploy(agentDeployment);
            case DeploymentStrategy.ROLLING_UPDATE:
                return await this.rollingUpdateDeploy(agentDeployment);
            case DeploymentStrategy.CANARY:
                return await this.canaryDeploy(agentDeployment);
            default:
                throw new Error(`Unsupported deployment strategy: ${strategy}`);
        }
    }

    private async blueGreenDeploy(deployment: AgentDeployment): Promise<DeploymentResult> {
        const currentVersion = this.currentVersion.get(deployment.agentId);
        const newVersion = deployment.version;
        
        // Deploy to green environment
        const greenEnvironment = await this.deployToEnvironment(
            deployment, 
            'green',
            newVersion
        );
        
        // Route 5% traffic to green environment
        await this.adjustTrafficSplit(deployment.agentId, { blue: 0.95, green: 0.05 });
        
        // Wait for monitoring signals
        const healthCheckPassed = await this.monitorHealth(
            deployment.agentId, 
            30000, // 30 seconds
            0.05 // Allow 5% error rate
        );
        
        if (healthCheckPassed) {
            // Route all traffic to green
            await this.adjustTrafficSplit(deployment.agentId, { blue: 0, green: 1 });
            this.currentVersion.set(deployment.agentId, newVersion);
            
            return {
                success: true,
                version: newVersion,
                strategy: 'blue-green',
                trafficSplit: { blue: 0, green: 1 }
            };
        } else {
            // Rollback to blue environment
            await this.adjustTrafficSplit(deployment.agentId, { blue: 1, green: 0 });
            await this.cleanupEnvironment('green');
            
            return {
                success: false,
                error: 'Health check failed after deployment',
                rollback: true
            };
        }
    }
}
```

### 2. Configuration Management for Agents

```typescript
// deployment/agent-configuration.ts
export interface AgentConfiguration {
    environment: 'development' | 'staging' | 'production';
    maxConcurrentTasks: number;
    retryPolicy: RetryPolicy;
    resourceLimits: ResourceLimits;
    featureFlags: FeatureFlags;
    networkSettings: NetworkSettings;
    securitySettings: SecuritySettings;
}

interface FeatureFlags {
    enableZKProofs: boolean;
    enableFraudDetection: boolean;
    enableMLPrediction: boolean;
    enableCaching: boolean;
    debugMode: boolean;
}

class AgentConfigurationService {
    private configurations: Map<string, AgentConfiguration> = new Map();
    private configVersion: Map<string, string> = new Map();

    async getConfiguration(agentId: string): Promise<AgentConfiguration> {
        const cachedConfig = this.configurations.get(agentId);
        
        if (cachedConfig && this.isConfigFresh(agentId)) {
            return cachedConfig;
        }

        const freshConfig = await this.fetchConfiguration(agentId);
        this.configurations.set(agentId, freshConfig);
        this.configVersion.set(agentId, freshConfig.version);
        
        return freshConfig;
    }

    async updateConfiguration(agentId: string, update: Partial<AgentConfiguration>): Promise<void> {
        const currentConfig = await this.getConfiguration(agentId);
        const updatedConfig = { ...currentConfig, ...update, version: this.generateVersion() };
        
        await this.validateConfiguration(updatedConfig);
        await this.saveConfiguration(agentId, updatedConfig);
        
        // Notify agent of configuration change
        await this.notifyAgent(agentId, 'config.updated', {
            version: updatedConfig.version,
            changes: Object.keys(update)
        });
        
        this.configurations.set(agentId, updatedConfig);
    }

    private async validateConfiguration(config: AgentConfiguration): Promise<void> {
        // Validate against JSON schema
        const validationResult = this.configSchema.validate(config);
        if (!validationResult.valid) {
            throw new Error(`Invalid configuration: ${validationResult.errors}`);
        }

        // Business rule validation
        if (config.maxConcurrentTasks <= 0) {
            throw new Error('maxConcurrentTasks must be greater than 0');
        }

        if (config.resourceLimits.memoryMB < this.MIN_MEMORY_LIMIT) {
            throw new Error('Memory limit too low');
        }
    }
}
```

The multi-agent system in ZKredit is designed with robust architecture patterns that ensure reliability, scalability, and maintainability. By employing proper communication patterns, state management, error handling, and deployment strategies, the system can handle complex workflows while maintaining high availability and performance.
