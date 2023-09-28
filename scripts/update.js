const {ethers,upgrades} = require('hardhat');

const proxy_address = "0x";

async function main() {
  // Upgrading
  const mycontractV2 = await ethers.getContractFactory("ContractV2");
  const upgraded = await upgrades.upgradeProxy(proxy_address, mycontractV2);
  console.log(`
    Upgrade (proxy): ${upgraded.address}\n`
  )
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});