/* Collateral Verifier Circuit for ZKredit System
 * This circuit proves that collateral is valid and sufficient
 * for securing a loan without revealing specific details
 */

pragma circom 2.0.0;

// Include necessary libraries
include "comparators.circom";
include "hashes/poseidon/poseidon.circom";

template CollateralVerifier() {
    // Public inputs (to be revealed)
    signal input requiredCollateralValue;  // Minimum required collateral value
    signal input collateralRatio;        // Required collateral-to-loan ratio (e.g., 150 for 150%)
    signal input minCollateralAge;       // Minimum age requirements in days
    signal output collateralStatus;      // Whether collateral is acceptable (0 or 1)
    signal output collateralScore;       // Collateral quality score (0-100)
    
    // Private inputs (to be kept secret)
    signal input actualCollateralValue;  // Actual collateral value (private)
    signal input collateralAge;          // Age of collateral in days (private)
    signal input loanAmount;             // Loan amount requested (private)
    signal input hasLiens;               // Whether collateral has liens on it (0 or 1) (private)
    signal input ownershipVerified;      // Whether ownership is verified (0 or 1) (private)
    signal input assetHash;              // Hash of asset details (private)
    
    // Additional private inputs for detailed analysis
    signal input assetType;              // Type of asset (private)
    signal input geographicRisk;         // Geographic risk factor (0-100) (private)
    signal input marketVolatility;       // Market volatility indicator (0-100) (private)
    
    // Intermediate signals
    signal collateralRatioCalculated;
    signal ageRequirementMet;
    signal valueRequirementMet;
    signal liensCheckPassed;
    signal ownershipCheckPassed;
    signal geographicCheckPassed;
    signal volatilityCheckPassed;
    
    // 1. Calculate collateral ratio (collateral-to-loan ratio)
    // collateralRatioCalculated = (actualCollateralValue * 100) / loanAmount
    signal collateralValue100;
    collateralValue100 <== actualCollateralValue * 100;
    collateralRatioCalculated <== collateralValue100 / loanAmount;
    
    // Prove that collateral ratio meets requirement
    component ratioGTE = GreaterEqThan(252);
    ratioGTE.in[0] <== collateralRatioCalculated;
    ratioGTE.in[1] <== collateralRatio;
    ratioGTE.out === 1;
    
    // 2. Prove that collateral age meets minimum requirements
    component ageGTE = GreaterEqThan(252);
    ageGTE.in[0] <== collateralAge;
    ageGTE.in[1] <== minCollateralAge;
    ageGTE.out === 1;
    ageRequirementMet <== 1;
    
    // 3. Prove that collateral value meets minimum requirements
    component valueGTE = GreaterEqThan(252);
    valueGTE.in[0] <== actualCollateralValue;
    valueGTE.in[1] <== requiredCollateralValue;
    valueGTE.out === 1;
    valueRequirementMet <== 1;
    
    // 4. Prove that collateral has no liens
    component zeroLiens = IsZero();
    zeroLiens.in <== hasLiens;
    zeroLiens.out === 1;
    liensCheckPassed <== 1;
    
    // 5. Prove that ownership is verified
    component verifiedOwnership = IsOne();
    verifiedOwnership.in <== ownershipVerified;
    verifiedOwnership.out === 1;
    ownershipCheckPassed <== 1;
    
    // 6. Prove geographic risk is acceptable (score <= 80)
    component geoRiskLTE = LessEqThan(252);
    geoRiskLTE.in[0] <== geographicRisk;
    geoRiskLTE.in[1] <== 80;
    geoRiskLTE.out === 1;
    geographicCheckPassed <== 1;
    
    // 7. Prove market volatility is within acceptable limits (score <= 70)
    component volatilityLTE = LessEqThan(252);
    volatilityLTE.in[0] <== marketVolatility;
    volatilityLTE.in[1] <== 70;
    volatilityLTE.out === 1;
    volatilityCheckPassed <== 1;
    
    // Calculate overall collateral status
    // All checks must pass for collateral to be acceptable
    collateralStatus <== ownershipCheckPassed * liensCheckPassed * valueRequirementMet * 
                       ageRequirementMet * geographicCheckPassed * volatilityCheckPassed;
    
    // Create a comprehensive collateral score (0-100)
    // Based on multiple factors:
    // - Collateral ratio quality (0-40 points)
    // - Collateral age bonus (0-20 points)
    // - Geographic stability (0-20 points)
    // - Market stability (0-20 points)
    
    // Score calculation with weighting
    signal ratioScore;
    signal ageScore;
    signal geoScore;
    signal volatilityScore;
    
    // Ratio score (0-40 points based on how much above requirement)
    signal ratioBonus;
    component ratioMultiplier = Multiplication();
    ratioMultiplier.a <== collateralRatioCalculated - collateralRatio;
    ratioMultiplier.b <== 2; // 2 points per percent above requirement
    ratioBonus <== ratioMultiplier.out;
    
    // Cap at 40 points
    component ratioCap = MinComparator();
    ratioCap.a <== ratioBonus;
    ratioCap.b <== 40;
    ratioScore <== ratioCap.out;
    
    // Age score (0-20 points based on age above minimum)
    signal ageBonus;
    ageBonus <== (collateralAge - minCollateralAge) * 1; // 1 point per day above minimum
    component ageCap = MinComparator();
    ageCap.a <== ageBonus;
    ageCap.b <== 20;
    ageScore <== ageCap.out;
    
    // Geographic score (inverse of risk)
    geoScore <== 100 - geographicRisk;
    
    // Volatility score (inverse of volatility)
    volatilityScore <== 100 - marketVolatility;
    
    // Calculate final score with weighting
    // - Ratio: 40% weight
    // - Age: 20% weight  
    // - Geographic: 20% weight
    // - Volatility: 20% weight
    signal weightedRatio;
    signal weightedAge;
    signal weightedGeo;
    signal weightedVol;
    signal totalScore;
    
    weightedRatio <== ratioScore * 40 / 100;
    weightedAge <== ageScore * 20 / 100;
    weightedGeo <== (geoScore * 100 / 100) * 20 / 100; // Normalize and apply weight
    weightedVol <== (volatilityScore * 100 / 100) * 20 / 100; // Normalize and apply weight
    
    totalScore <== weightedRatio + weightedAge + weightedGeo + weightedVol;
    
    // Cap final score at 100
    component finalCap = MinComparator();
    finalCap.a <== totalScore;
    finalCap.b <== 100;
    collateralScore <== finalCap.out;
    
    // Security constraints
    // Ensure all values are positive
    component checkValue1 = GreaterEqThan(252);
    checkValue1.in[0] <== actualCollateralValue;
    checkValue1.in[1] <== 0;
    checkValue1.out === 1;
    
    component checkValue2 = GreaterEqThan(252);
    checkValue2.in[0] <== collateralAge;
    checkValue2.in[1] <== 0;
    checkValue2.out === 1;
    
    component checkValue3 = GreaterEqThan(252);
    checkValue3.in[0] <== requiredCollateralValue;
    checkValue3.in[1] <== 0;
    checkValue3.out === 1;
}

/* Helper components */

template Multiplication() {
    signal input a;
    signal input b;
    signal output out;
    out <== a * b;
}

template MinComparator() {
    signal input a;
    signal input b;
    signal output out;
    
    // Returns min(a, b)
    component lt = LessThan(252);
    lt.in[0] <== a;
    lt.in[1] <== b;
    
    signal lessThan;
    lessThan <== lt.out;
    
    // If a < b, return a, otherwise return b
    // out = a * lessThan + b * (1 - lessThan)
    signal notLess;
    notLess <== 1 - lessThan;
    
    signal aWeighted;
    aWeighted <== a * lessThan;
    
    signal bWeighted;
    bWeighted <== b * notLess;
    
    out <== aWeighted + bWeighted;
}

template IsOne() {
    signal input in;
    signal output out;
    out === 1;
    in === out;
}

/* Main component for testing and compilation */
component main {public [requiredCollateralValue, collateralRatio, minCollateralAge]} = CollateralVerifier();
