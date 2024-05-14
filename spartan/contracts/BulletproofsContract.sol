// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "../src/bn254/BN254.sol";
import "../src/bn254/BN256G2.sol";
import "../src/bn254/Fields.sol";
import "../src/Utils.sol";
import "../src/nizk/BulletproofsVerifier.sol";

contract BulletproofsContract {

    event ProofVerified(uint256 G_hat_x, uint256 G_hat_y, uint256 Gamma_hat_x, uint256 Gamma_hat_y, uint256 a_hat);

    function verifyProof(uint256[][] memory L_vec_in, uint256[][] memory R_vec_in, uint256[][] memory G_vec_in, uint256[] memory a_vec_in, uint256[] memory gamma_in) public returns (bool) {
        uint256 n = a_vec_in.length;
        BN254.G1Point[] memory L_vec = new BN254.G1Point[](L_vec_in.length);
        BN254.G1Point[] memory R_vec = new BN254.G1Point[](R_vec_in.length);
        for(uint i = 0; i < L_vec_in.length; i++){
            L_vec[i] = BN254.G1Point(L_vec_in[i][0], L_vec_in[i][1]);
            R_vec[i] = BN254.G1Point(R_vec_in[i][0], R_vec_in[i][1]);
        }
        BN254.G1Point[] memory G_vec = new BN254.G1Point[](G_vec_in.length);
        for(uint i = 0; i < G_vec_in.length; i++){
            G_vec[i] = BN254.G1Point(G_vec_in[i][0], G_vec_in[i][1]);
        }
        BN254.G1Point memory Gamma = BN254.G1Point(gamma_in[0], gamma_in[1]);
        (BN254.G1Point memory G_hat, BN254.G1Point memory Gamma_hat, uint256 a_hat) = BulletproofsVerifier.verify(n, a_vec_in, L_vec, R_vec, G_vec, Gamma);
        emit ProofVerified(G_hat.x, G_hat.y, Gamma_hat.x, Gamma_hat.y, a_hat);
        return true;
    }
}