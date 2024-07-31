
# Run Deployment scripts
```
forge script script/TestnetDeployAll.s.sol:TestnetDeployAll --rpc-url base --etherscan-api-key base --verify --broadcast -- --max-fee-per-gas 10000000

forge script script/DeployAll.s.sol:DeployAll --rpc-url base --etherscan-api-key base --verify --broadcast -- --max-fee-per-gas 10000000
```

# Verify a contract on Etherscan that is already deployed
```
forge verify-contract --chain base 0x2cd3c02A734559472d91b285B544202A3C8B129e src/TruglyMemeception.sol:TruglyMemeception --etherscan-api-key base --constructor-args $(cast abi-encode "constructor(address,address,address,address)" 0x6EC48a5016A550D23156187C86451710c5ecc94A 0xDdC78Bb84f18D7a975aCebb21c8ac2AFb07d8a58 0xb2660C551AB31FAc6D01a75f628Af2d200FfD1F2 0x4f773Bfa7249BE81107e0E1944b99dfA26482270)

```
