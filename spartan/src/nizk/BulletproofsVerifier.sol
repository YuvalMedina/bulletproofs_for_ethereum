// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "../bn254/BN254.sol";
import "../bn254/BN256G2.sol";
import "../bn254/Fields.sol";
import "../Utils.sol";

using {BN254.add, BN254.scale_scalar, BN254.neg} for BN254.G1Point;
using {Scalar.neg, Scalar.add, Scalar.sub, Scalar.mul, Scalar.inv, Scalar.double, Scalar.pow, Scalar.square} for Scalar.FE;

// Author: @yuval-medina
library BulletproofsVerifier {

    function innerProd(
        uint256[] memory right, uint256[] memory left
    ) internal pure returns (Scalar.FE result) {
        result = Scalar.zero();
        for (uint i = 0; i < right.length; i++) {
            result = Scalar.add(result, Scalar.mul(Scalar.from(right[i]), Scalar.from(left[i])));
        }
    }

    function mostSignificantBit(uint256 x) private pure returns (uint256) {
        uint256 res = 0;
        while (x > 0) {
            res++;
            x >>= 1;
        }
        return res - 1;
    }

    function verificationScalars(
        uint256 n,
        uint256[] memory challenges
    ) internal view returns (uint256[] memory challenges_squared, uint256[] memory challenges_inv_squared, uint256[] memory s) {
        challenges_squared = new uint256[](challenges.length);
        challenges_inv_squared = new uint256[](challenges.length);
        s = new uint256[](challenges.length);

        Scalar.FE all_inv = Scalar.from(1);
        for (uint i = 0; i < challenges.length; i++) {
            Scalar.FE challenge = Scalar.from(challenges[i]);
            Scalar.FE challenge_inv = Scalar.inv(challenge);
            challenges_squared[i] = Scalar.FE.unwrap(Scalar.square(challenge));
            challenges_inv_squared[i] = Scalar.FE.unwrap(Scalar.square(challenge_inv));
            all_inv = Scalar.mul(all_inv, challenge_inv);
        }

        s[0] = Scalar.FE.unwrap(all_inv);
        for (uint i = 1; i < challenges.length; i++) {
            uint256 lg_i = mostSignificantBit(i);
            uint256 k = 1 << lg_i;
            uint256 u_lg_i_sq = challenges_squared[n - 1 - lg_i];
            // The challenges are stored in "creation order" as [u_k,...,u_1],
            // so u_{lg(i)+1} = is indexed by (lg_n-1) - lg_i
            s[i] = Scalar.FE.unwrap(Scalar.mul(Scalar.from(s[i-k]), Scalar.from(u_lg_i_sq)));
        }
    }

    function computeChallenges(uint256 n) internal pure returns (uint256[] memory challenges) {
        uint256 seed = 4017;
        challenges = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            // Simplified challenge computation
            challenges[i] = uint256(keccak256(abi.encodePacked(seed, i)));
        }
    }

    function fillBases(BN254.G1Point[] memory L_vec, BN254.G1Point[] memory R_vec, BN254.G1Point memory Gamma)
        internal pure returns (BN254.G1Point[] memory bases) {
        bases = new BN254.G1Point[](L_vec.length + R_vec.length + 1);
        for (uint256 i = 0; i < L_vec.length; i++) {
            bases[i] = L_vec[i];
        }
        for (uint256 i = 0; i < R_vec.length; i++) {
            bases[L_vec.length + i] = R_vec[i];
        }
        bases[L_vec.length + R_vec.length] = Gamma;
    }

    function fillScalars(uint256[] memory u_sq, uint256[] memory u_inv_sq) internal pure returns (uint256[] memory scalars) {
        scalars = new uint256[](u_sq.length + u_inv_sq.length + 1);
        for (uint256 i = 0; i < u_sq.length; i++) {
            scalars[i] = u_sq[i];
        }
        for (uint256 i = 0; i < u_inv_sq.length; i++) {
            scalars[u_sq.length + i] = u_inv_sq[i];
        }
        scalars[u_sq.length + u_inv_sq.length] = 1;
    }

    function verify(
        uint256 n, uint256[] memory a, BN254.G1Point[] memory L_vec, BN254.G1Point[] memory R_vec, BN254.G1Point[] memory G, BN254.G1Point memory Gamma
    ) public view returns (BN254.G1Point memory G_hat, BN254.G1Point memory Gamma_hat, uint256 a_hat) {
        uint256[] memory challenges = computeChallenges(n);
        (uint256[] memory u_sq, uint256[] memory u_inv_sq, uint256[] memory s) = verificationScalars(n, challenges);

        G_hat = BN254.multiScalarMul(G, s);
        a_hat = Scalar.FE.unwrap(innerProd(a, s));

        BN254.G1Point[] memory bases = fillBases(L_vec, R_vec, Gamma);
        uint256[] memory scalars = fillScalars(u_sq, u_inv_sq);

        // Compute Gamma_hat using msm
        Gamma_hat = BN254.multiScalarMul(bases, scalars);

        return (G_hat, Gamma_hat, a_hat);
    }
}