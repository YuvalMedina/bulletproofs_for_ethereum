import fs from 'fs';
import path from 'path';
import { ethers, toBigInt } from 'ethers';
import { execFile } from 'child_process';
// Import the contract JSON directly from the build folder
import contractJson from '../../build/contracts/BulletproofsContract.json';

// Connect to the Ethereum network
const provider = new ethers.JsonRpcProvider('http://localhost:8545');

// Generate a new wallet (REPLACE here with private key printed by Ganache)
const wallet = new ethers.Wallet('0xc01446831b25d1437e7c3c571fe2b6cdbe72c6916879748b9a1b5bc9b2afbf79', provider);

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
const binary_prover_runner_path = path.resolve("../target/release/bullet_prover");

main().catch(console.error);

// Function to run the Rust binary and capture its output
function runRustBinary(binaryPath: string, args: string[]): Promise<any> {
  return new Promise((resolve, reject) => {
    execFile(binaryPath, args, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      if (stderr) {
        reject(new Error(stderr));
        return;
      }

      // Define regex patterns to capture the output
      const lVecPattern = /L_vec:\s*\n((?:\t\tpoint: \((\d+), (\d+)\)\n)*)/gm;
      const rVecPattern = /R_vec:\s*\n((?:\t\tpoint: \((\d+), (\d+)\)\n)*)/gm;
      const gVecPattern = /Input G_vec:\s*\n((?:\t\tpoint: \((\d+), (\d+)\)\n)*)/gm;
      const aVecPattern = /Input a_vec:\s*\n((?:\t\ta_scalar: (\d+)\n)*)/gm;
      const gammaPattern = /Input H:\s*\((\d+),\s*(\d+)\)/;

      // Use regex to find and capture the data
      const lVecMatch = lVecPattern.exec(stdout);
      const rVecMatch = rVecPattern.exec(stdout);
      const gVecMatch = gVecPattern.exec(stdout);
      const aVecMatch = aVecPattern.exec(stdout);
      const gammaMatch = gammaPattern.exec(stdout);

      // Helper function to process vector matches
      const processVec = (match: RegExpExecArray | null): [bigint, bigint][] => {
        if (!match) return [];
        const points = match[1].trim().split('\n');
        return points.map(line => {
          const pointMatch = /\((\d+), (\d+)\)/.exec(line);
          if (pointMatch) {
            return [toBigInt(pointMatch[1].trim()), toBigInt(pointMatch[2].trim())];
          }
          return [0n, 0n];
        });
      };

      // Helper function to process aVec matches
      const processScalarVec = (match: RegExpExecArray | null): bigint[] => {
        if (!match) return [];
        return match[1].trim().split('\n').map(line => {
          const scalarMatch = /(\d+)/.exec(line);
          return scalarMatch ? toBigInt(scalarMatch[1].trim()) : 0n;
        });
      };

      // Process captured data
      const lVec = processVec(lVecMatch);
      const rVec = processVec(rVecMatch);
      const gVec = processVec(gVecMatch);
      const aVec = processScalarVec(aVecMatch);

      // Process H vector
      const gamma = gammaMatch ? [
        toBigInt(gammaMatch[1].trim()),
        toBigInt(gammaMatch[2].trim())
      ] : [];

      // Resolve the promise with an object containing the parsed data
      resolve({ lVec, rVec, gVec, aVec, gamma });
    });
  });
}

async function main() {
    // The inputs you want to provide to the verifyProof function
    //const inputs = [/*Gamma_hat:*/[2468653035702945611616543905036121038408045641787679119784134167106679361695, 7463754748330605196985773520854968194272045409125008156874137525281687155320],
    //                /*a:*/13092778897486157864792145214823398581642344982970391047387368366289569747780,
    //                /*b:*/20981047141542797994926667680796934580773240320642184916774284536212862101573,
    //                /*g:*/[8272905359926183817462908290819828413034252559830488622002686207946142933262, 5666516865670064489109557642115051241965904673374343959975717983980167077465],
    //                /*blind fin:*/12904615688960069764882999465544574537163152887435311007099518640076951109637];

    try {;
      var {lVec, rVec, gVec, aVec, gamma} = await runRustBinary(binary_prover_runner_path, []);
      console.log('L_vec: ', lVec);
      console.log('R_vec: ', rVec);
      console.log('G_vec: ', gVec);
      console.log('a_vec: ', aVec);
      console.log('gamma: ', gamma);

      const tx = await contract.verifyProof(lVec, rVec, gVec, aVec, gamma);
      await tx.wait(); // Wait for the transaction to be mined
      console.log('Proof verification transaction: ', tx);
    } catch (error) {
      console.error('An error occurred while proving and verifying the bulletproof: ', error);
      // Additional error handling or logging can go here
    }
  }
  
  main().catch(console.error);