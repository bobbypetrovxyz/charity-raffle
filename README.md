## How to install

```
$ forge install
```

## How to test

No automation tests

## Deployment steps

1. Add SEPOLIA_RPC_URL and ETHERSCAN_API_KEY in .env

```
SEPOLIA_RPC_URL=
ETHERSCAN_API_KEY=
```

2. Run deploy script

```
$ forge script script/deploy.s.sol:DeployScript --broadcast --verify -vvvv --rpc-url sepolia --private-key <> --etherscan-api-key "${ETHERSCAN_API_KEY}"
```

3. Run verify script if needed

```
$ forge verify-contract <address>  ./src/CharityRaffle.sol:CharityRaffle --chain-id 11155111 --api-key "${ETHERSCAN_API_KEY}"
```

## Links to contracts

- Proxy - 0x8D1F1984CA98A1a7a4dA79B85C7946F67D429De2
- Implementation - 0x2442C99BF0B7638fFFBfa1345A3ed064c8deb2CC

## Proof of execution

- ticket purchase - https://sepolia.etherscan.io/tx/0xff8c32207b959ff51e2e755e7bbf5110c647c73e35bd1242b3e119b2269470dd
- request random winners - https://sepolia.etherscan.io/tx/0x8121bf5e9f8c470698315cc41dfb8e351577b1c0fde822b7f95d5029e3f617fd
- fulfill random words - https://sepolia.etherscan.io/tx/0xbd1578a5a5018c7a20b9cdea8bcdac6759959b7bd08020010f1a5a754f9ff653
- claim prize - https://sepolia.etherscan.io/tx/0xd3c6aa56e58898010fdb378048c26d21ef5b23ccb8809848198dbef51b927db7
- claim charity funds - https://sepolia.etherscan.io/tx/0x87875b064ae91cf557557c128e52fa14edabeec581c4457dc06b0f41996193ce
