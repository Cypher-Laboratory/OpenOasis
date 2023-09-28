const {ethers,upgrades} = require('hardhat');

async function main() {
  //Deploying
  const mycontract = await ethers.getContractFactory('EVMVerifier')
  const mycontract_instance = await upgrades.deployProxy(mycontract,{ initializer: 'initialize',kind: 'uups'});
  await mycontract_instance.deployed();

  console.log(`
    Contract instance (proxy): ${mycontract_instance.address}\n`
  )
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});