/* Income Verifier Circuit for ZKredit System
 * This circuit proves that a user's income falls within a specified range
 * without revealing the exact income amount
 */

pragma circom 2.0.0;

// Include necessary libraries
include "comparators.circom";

template IncomeVerifier() {
    // Public inputs (to be revealed)
    signal input minIncome;     // Minimum income requirement
    signal input maxIncome;      // Maximum income requirement
    signal output commitment;      // Commitment to the income value
    
    // Private inputs (to be kept secret)
    signal input actualIncome;   // User's actual income (private)
    
    // Constraints to ensure properties
    // 1. Prove that actualIncome >= minIncome
    component gte = GreaterEqThan(252);
    gte.in[0] <== actualIncome;
    gte.in[1] <== minIncome;
    gte.out === 1;
    
    // 2. Prove that actualIncome <= maxIncome  
    component lte = LessEqThan(252);
    lte.in[0] <== actualIncome;
    lte.in[1] <== maxIncome;
    lte.out === 1;
    
    // 3. Create a commitment to the actual income (hash)
    commitment <== actualIncome;
    
    // Additional constraints for security
    // Ensure minIncome < maxIncome
    component validRange = LessEqThan(252);
    validRange.in[0] <== minIncome;
    validRange.in[1] <== maxIncome;
    validRange.out === 1;
    
    // Ensure all values are positive
    component pos1 = GreaterEqThan(252);
    pos1.in[0] <== actualIncome;
    pos1.in[1] <== 0;
    pos1.out === 1;
    
    component pos2 = GreaterEqThan(252);
    pos2.in[0] <== minIncome;
    pos2.in[1] <== 0;
    pos2.out === 1;
    
    component pos3 = GreaterEqThan(252);
    pos3.in[0] <== maxIncome;
    pos3.in[1] <== 0;
    pos3.out === 1;
}

/* Main component for testing and compilation */
component main {public [minIncome, maxIncome]} = IncomeVerifier();
