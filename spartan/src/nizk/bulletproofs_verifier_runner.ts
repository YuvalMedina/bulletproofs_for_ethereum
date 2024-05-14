import fs from 'fs';
import path from 'path';
import { ethers } from 'ethers';
// Import the contract JSON directly from the build folder
import contractJson from '../../build/contracts/BulletproofsContract.json';

// Connect to the Ethereum network
const provider = new ethers.JsonRpcProvider('http://localhost:8545');

// Generate a new wallet
const wallet = new ethers.Wallet('0x6401ee2a21b464aaf0e30876868b8c3983a8a9eb47619a24f9529afe61c94942', provider);

const contractABI = contractJson.abi;
const contractBytecode = contractJson.bytecode;

// Function to get the most recently added network ID
function getLatestNetworkId(contractJson: any): string {
  const networkIds = Object.keys(contractJson.networks);
  // Assuming the last network ID is the one you want to use
  return networkIds[networkIds.length - 1];
}
const networkId = getLatestNetworkId(contractJson);

// The address the contract is deployed to
const contractAddress = (contractJson.networks as any)[networkId].address;

// Create a contract instance
const contract = new ethers.Contract(contractAddress, contractABI, wallet);

main().catch(console.error);

async function main() {
    // The inputs you want to provide to the verifyProof function
    //const inputs = [/*Gamma_hat:*/[2468653035702945611616543905036121038408045641787679119784134167106679361695, 7463754748330605196985773520854968194272045409125008156874137525281687155320],
    //                /*a:*/13092778897486157864792145214823398581642344982970391047387368366289569747780,
    //                /*b:*/20981047141542797994926667680796934580773240320642184916774284536212862101573,
    //                /*g:*/[8272905359926183817462908290819828413034252559830488622002686207946142933262, 5666516865670064489109557642115051241965904673374343959975717983980167077465],
    //                /*blind fin:*/12904615688960069764882999465544574537163152887435311007099518640076951109637];

    try {
      const tx = await contract.verifyProof({gasLimit: 100000});
      await tx.wait(); // Wait for the transaction to be mined
      console.log('Proof verification transaction: ', tx);
    } catch (error) {
      console.error('An error occurred while executing the transaction: ', error);
      // Additional error handling or logging can go here
    }
  }
  
  main().catch(console.error);