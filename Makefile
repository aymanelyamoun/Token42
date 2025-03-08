all:
	npx hardhat compile
	npx hardhat ignition deploy ./ignition/modules/carbonToken.js --network moonbase --verify
clean:
	npx hardhat clean