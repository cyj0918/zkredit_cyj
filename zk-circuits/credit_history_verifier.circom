/* Credit History Verifier Circuit for ZKredit System
 * This circuit proves that a user has a good credit history
 * without revealing specific credit scores or payment history
 */

pragma circom 2.0.0;

// Include necessary libraries
include "comparators.circom";

template CreditHistoryVerifier() {
    // Public inputs (to be revealed)
    signal input creditScoreMin;     // Minimum credit score required
    signal input creditScoreMax;        // Maximum credit score acceptable  
    signal input minHistoryLength;     // Minimum credit history length in months
    signal output creditRating;         // Credit rating (0-100)
    signal output isEligible;           // Whether user is eligible (0 or 1)
    
    // Private inputs (to be kept secret)
    signal input creditScore;            // User's actual credit score (private)
    signal input historyLength;          // Length of credit history in months (private)
    signal input defaultCount;           // Number of defaults (private)
    signal input recentLatePayments;     // Recent late payments count (private)
    
    // Constraints to prove creditworthiness
    // 1. Prove that creditScore is within required range
    component scoreGTE = GreaterEqThan(252);
    scoreGTE.in[0] <== creditScore;
    scoreGTE.in[1] <== creditScoreMin;
    scoreGTE.out === 1;
    
    component scoreLTE = LessEqThan(252);
    scoreLTE.in[0] <== creditScore;
    scoreLTE.in[1] <== creditScoreMax;
    scoreLTE.out === 1;
    
    // 2. Prove that history length meets minimum requirement
    component historyGTE = GreaterEqThan(252);
    historyGTE.in[0] <== historyLength;
    historyGTE.in[1] <== minHistoryLength;
    historyGTE.out === 1;
    
    // 3. Prove that user has no recent defaults (last 2 years)
    component zeroDefaults = IsZero();
    zeroDefaults.in <== defaultCount;
    zeroDefaults.out === 1;
    
    // 4. Prove that user has a reasonable number of late payments (fewer than 3)
    component limitedLatePayments = LessEqThan(252);
    limitedLatePayments.in[0] <== recentLatePayments;
    limitedLatePayments.in[1] <== 3;
    limitedLatePayments.out === 1;
    
    // Calculate overall credit eligibility
    // User is eligible if they pass all the above criteria
    isEligible <== 1;
    
    // Calculate a credit rating (0-100) based on score and history
    // This is a simplified calculation for the circuit
    component scaledRating = MultiDivision();
    scaledRating.dividend <== creditScore;
    scaledRating.divisor <== 850; // Max credit score
    scaledRating.ratio <== 100; // Scale to 0-100
    
    creditRating <== scaledRating.remainder;
    
    // Additional constraints for security
    // Ensure all inputs are valid ranges
    component pos1 = GreaterEqThan(252);
    pos1.in[0] <== creditScore;
    pos1.in[1] <== 0;
    pos1.out === 1;
    
    component pos2 = GreaterEqThan(252);
    pos2.in[0] <== historyLength;
    pos2.in[1] <== 0;
    pos2.out === 1;
    
    // Ensure credit score is reasonable (0-850 range)
    component validScoreRange = LessEqThan(252);
    validScoreRange.in[0] <== creditScore;
    validScoreRange.in[1] <== 850;
    validScoreRange.out === 1;
}

template MultiDivision() {
    signal input dividend;
    signal input divisor;
    signal input ratio;
    signal output remainder;
    
    // Calculate remainder = (dividend * ratio) / divisor
    signal scaledDividend;
    scaledDividend <== dividend * ratio;
    
    remainder <== scaledDividend / divisor;
}

/* Main component for testing and compilation */
component main {public [creditScoreMin, creditScoreMax, minHistoryLength]} = CreditHistoryVerifier();
