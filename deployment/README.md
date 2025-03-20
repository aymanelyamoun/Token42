STEPS USED TO DEPLOY THE CONTRACT

# go to deployment folder
```
cd deployment
```
# install hardhat dependencies
```
npm i
```

# copy the contrcts from code
```
cp -r ../code/contracts ./contracts
```

# deploy to the moonbase alpha testnet
```
npx hardhat ignition deploy ./ignition/modules/carbonToken.js --network moonbase
```

# verify the contract
```
npx hardhat ignition verify chain-1287
```
