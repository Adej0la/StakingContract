// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const ERC20Token = await hre.ethers.getContractFactory("SubaruERC20");
  const ERC721Token = await hre.ethers.getContractFactory("SubaruERC721");
  const fungible = await ERC20Token.deploy();
  const nonFungible = await ERC721Token.deploy();

  await fungible.deployed();
  await nonFungible.deployed();

  console.log("fungible Tokens deployed to: ", fungible.address);
  console.log("Non-fungible Tokens deployed to: ", nonFungible.address);

  const buyTxn = await fungible.buy();
  await buyTxn.wait;

  const mintTxn = await nonFungible.safeMint();
  await mintTxn.wait;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
