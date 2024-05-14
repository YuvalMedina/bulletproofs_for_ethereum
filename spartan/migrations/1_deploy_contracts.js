const BulletproofsVerifier = artifacts.require("BulletproofsVerifier");

module.exports = function (deployer) {
    deployer.deploy(BulletproofsVerifier);
};