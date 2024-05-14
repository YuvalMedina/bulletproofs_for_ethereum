const BulletproofsVerifier = artifacts.require("BulletproofsVerifier");
const BulletproofsContract = artifacts.require("BulletproofsContract");

module.exports = function (deployer) {
    deployer.deploy(BulletproofsVerifier).then(function() {
        return deployer.link(BulletproofsVerifier, BulletproofsContract).then(function() {
            return deployer.deploy(BulletproofsContract);
        });
    });
};