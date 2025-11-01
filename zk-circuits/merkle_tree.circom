/* Merkle Tree Circuit for ZKredit System
 * This circuit proves membership in a Merkle tree
 * for identity verification and transaction integrity
 */

pragma circom 2.0.0;

// Include necessary libraries
include "hashes/poseidon/poseidon.circom";

template MerkleTreeVerifier(levels) {
    // Public inputs (to be revealed)
    signal input root;                    // Merkle tree root (public)
    signal input pathIndices[levels];     // Path indices (0 for left, 1 for right) (public)
    
    // Private inputs (to be kept secret)
    signal input leafHash;               // Hash of the leaf data (private)
    signal input pathElements[levels];  // Sibling nodes along the path (private)

    // Output
    signal output isValid;              // Whether the membership proof is valid (0 or 1)

    // Verify the Merkle proof
    signal currentHash;
    currentHash <== leafHash;

    // Hash the leaf data to obtain the leaf hash
    // In this simplified version, we assume leafHash is already computed
    // component leafHasher = Poseidon(1);
    // leafHasher.inputs[0] <== leafData;
    // leafHash <== leafHasher.out;

    // Calculate the Merkle root by traversing from leaf to root
    component hashers[levels];
    
    for (var i = 0; i < levels; i++) {
        component poseidonHash = Poseidon(2);
        hashers[i] = poseidonHash;
        
        // Hash the current node with the sibling node
        signal leftChild;
        signal rightChild;
        
        // Determine left and right children based on path direction
        if (pathIndices[i] == 0) {
            // Current is left child
            leftChild <== currentHash;
            rightChild <== pathElements[i];
        } else {
            // Current is right child
            leftChild <== pathElements[i];
            rightChild <== currentHash;
        }
        
        hashers[i].inputs[0] <== leftChild;
        hashers[i].inputs[1] <== rightChild;
        
        // Update current hash to parent hash
        currentHash <== hashers[i].out;
    }

    // Verify the computed root matches the provided root
    isValid <== (currentHash == root);

    // Ensure the proof is valid (root match)
    component rootMatch = IsEqual();
    rootMatch.in[0] <== currentHash;
    rootMatch.in[1] <== root;
    rootMatch.out === isValid;

    // Additional validation constraints
    // Ensure path indices are binary (0 or 1)
    for (var i = 0; i < levels; i++) {
        component binaryCheck = IsBinary();
        binaryCheck.in <== pathIndices[i];
        binaryCheck.out === isValid;
    }
}

template IsBinary() {
    signal input in;
    signal output out;
    
    // Input must be either 0 or 1
    // out = in * (1 - in)
    out <== in * (1 - in);
    out === 0;
}

template IsEqual() {
    signal input in[2];
    signal output out;
    
    // Equality check: out = 1 if in[0] == in[1], else 0
    out <== in[0] == in[1];
}

/* Identity Verification Circuit - Specific use case for ZKredit */
template IdentityVerification(levels) {
    // Public inputs
    signal input identityRoot;           // Merkle root of identity tree
    signal input pathIndices[levels];     // Path through identity tree
    
    // Private inputs
    signal input userHash;               // Hash of user identity data
    signal input identityPath[levels];   // Path components in identity tree
    
    // Additional verification data
    signal output verificationResult;    // 1 if identity verified, 0 otherwise
    
    // Verify Merkle proof of identity
    component merkleVerifier = MerkleTreeVerifier(levels);
    merkleVerifier.root <== identityRoot;
    merkleVerifier.leafHash <== userHash;
    
    for (var i = 0; i < levels; i++) {
        merkleVerifier.pathIndices[i] <== pathIndices[i];
        merkleVerifier.pathElements[i] <== identityPath[i];
    }
    
    verificationResult <== merkleVerifier.isValid;
    
    // Additional identity-specific constraints could be added here
    // For example, verification of KYC status, age verification, etc.
}

/* Transaction commitment verification */
template TransactionVerification(levels) {
    // Public inputs
    signal input transactionRoot;        // Merkle root of transaction tree
    signal input pathIndices[levels];    // Path indices
    
    // Private inputs
    signal input transactionHash;        // Hash of transaction data
    signal input transactionPath[levels]; // Path components in transaction tree
    signal input timestamp;              // Transaction timestamp (private)
    signal input currentTime;            // Current time (private)
    
    // Verify transaction is valid and recent (within last 30 days)
    signal output transactionValid;        // Whether transaction is valid
    
    // Time constraint: transaction must be recent
    component recentTransaction = GreaterEqThan(252);
    recentTransaction.in[0] <== currentTime - timestamp;
    recentTransaction.in[1] <== 0; // Within last block (simplified)
    recentTransaction.out === 1;
    
    // Verify transaction is in the Merkle tree
    component transactionMerkle = MerkleTreeVerifier(levels);
    transactionMerkle.root <== transactionRoot;
    transactionMerkle.leafHash <== transactionHash;
    
    for (var i = 0; i < levels; i++) {
        transactionMerkle.pathIndices[i] <== pathIndices[i];
        transactionMerkle.pathElements[i] <== transactionPath[i];
    }
    
    transactionValid <== transactionMerkle.isValid;
}

/* Batch processing for multiple proofs */
template BatchMerkleVerifier(batchSize, levels) {
    // Array of proofs to verify simultaneously
    signal input batchRoots[batchSize];
    signal input batchLeaves[batchSize];
    signal input batchPaths[batchSize][levels];
    signal input batchIndices[batchSize][levels];
    
    signal output allValid;  // 1 if all proofs are valid, 0 otherwise
    
    // Verify each Merkle proof individually
    component verifiers[batchSize];
    signal validityFlags[batchSize];
    
    for (var i = 0; i < batchSize; i++) {
        verifiers[i] = MerkleTreeVerifier(levels);
        verifiers[i].root <== batchRoots[i];
        verifiers[i].leafHash <== batchLeaves[i];
        
        for (var j = 0; j < levels; j++) {
            verifiers[i].pathIndices[j] <== batchIndices[i][j];
            verifiers[i].pathElements[j] <== batchPaths[i][j];
        }
        
        validityFlags[i] <== verifiers[i].isValid;
    }
    
    // Check if all proofs are valid
    allValid <== 1;
    for (var i = 0; i < batchSize; i++) {
        allValid <== allValid * validityFlags[i];
    }
    
    // Additional constraint to ensure all proofs are actually valid
    component allValidCheck = IsEqual();
    for (var i = 0; i < batchSize; i++) {
        if (i == 0) {
            allValidCheck.in[0] <== validityFlags[i];
        }
        if (i > 0) {
            allValid <== allValid * validityFlags[i];
        }
    }
    allValidCheck.in[1] <== 1;
    allValidCheck.out === allValid;
}

// Main components for different use cases
component main_identity {public [identityRoot, pathIndices[4]]} = IdentityVerification(4);
component main_transaction {public [transactionRoot, pathIndices[3]]} = TransactionVerification(3);
component main_batch {public [batchRoots[2]]} = BatchMerkleVerifier(2, 4);
