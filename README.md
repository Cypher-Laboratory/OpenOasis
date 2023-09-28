# Alice's Ring - EVM Verifier


## Installation
To install Hardhat, clone this repo and go into the folder.  
```
npm install
```
Once it's installed, just run this command and follow its instructions:

1. Compile contracts  

```
npx hardhat compile
```

2. Local Deployment  

You can deploy in the `localhost` network following these steps:  

1. Start a local node

   ```
   npx hardhat node
   ```

2. Open a new terminal and deploy the smart contract in the `localhost` network

   ```
   npx hardhat run --network localhost scripts/deploy.js
   ```
     
3. Network deployment

Open a terminal and run :   
   ```
   npx hardhat run --network <scroll-goerli-sepolia-ethereum...> scripts/deploy.js
   ```  

As general rule, you can target any network from your Hardhat config using:

```
npx hardhat run --network <your-network> scripts/deploy.js
```
