// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "../src/bn254/BN254.sol";
import "../src/bn254/BN256G2.sol";
import "../src/bn254/Fields.sol";
import "../src/Utils.sol";
import "../src/nizk/BulletproofsVerifier.sol";

contract BulletproofsContract {

    event ProofVerified(uint256 G_hat_x, uint256 G_hat_y, uint256 Gamma_hat_x, uint256 Gamma_hat_y, uint256 a_hat);

    function verifyProof() public returns (bool) {
        uint256 n = 2;
        uint256[] memory a = new uint256[](2);
        a[0] = 15416814217601598809097438307159678280910647601202033136697015301739005538422;
        a[1] = 15416814217601598809097438307159678280910647601202033136697015301739005538422;
        BN254.G1Point[] memory L_vec = new BN254.G1Point[](1);
        L_vec[0] = BN254.G1Point(15709189654499547992253128989596772418908135586083873956644761776195579465707, 9378588439586703892386735522965228813309566421716910557705682863885074946828);
        BN254.G1Point[] memory R_vec = new BN254.G1Point[](1);
        R_vec[0] = BN254.G1Point(7935939072908026097295476399345016765187006381900055898480031549945872409687, 6677402905646868853420619353930623775394799189538162883048922076126975254240);
        BN254.G1Point[] memory G = new BN254.G1Point[](2);
        G[0] = BN254.G1Point(1,2);
        G[1] = BN254.G1Point(1,2);
        BN254.G1Point memory Gamma = BN254.G1Point(1,2);
        (BN254.G1Point memory G_hat, BN254.G1Point memory Gamma_hat, uint256 a_hat) = BulletproofsVerifier.verify(n, a, L_vec, R_vec, G, Gamma);
        emit ProofVerified(G_hat.x, G_hat.y, Gamma_hat.x, Gamma_hat.y, a_hat);
        return true;
    }
}