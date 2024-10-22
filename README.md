## Token smart contract

This directory a whole token creation and its respective vesting logic. It also counts with some logic regarding airdrops and token staking.

**This directory will contain all of the logic needed for a token release.**

Such as

- **Token contract**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Stake contract**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Airdrop proof and token giveout**: Local Ethereum node, akin to Ganache, Hardhat Network.

## Token Distribution

The following is the token distribution plan with vesting details for each category:

| Category          | Allocation percentage | Amount (Tokens) | Vesting Schedule                                              |
| ----------------- | --------------------- | --------------- | ------------------------------------------------------------- |
| Public Sale       | 15 %                  | 15,000,000      | 10% at TGE, 12-month linear vesting                           |
| Ecosystem Fund    | 25 %                  | 25,000,000      | 5% at TGE, 24-month linear vesting                            |
| Staking Rewards   | 25 %                  | 25,000,000      | 36-month vesting: 40% in year 1, 35% in year 2, 25% in year 3 |
| Team and Advisors | 20 %                  | 20,000,000      | 12-month cliff, 36-month vesting                              |
| Private Sale      | 10 %                  | 10,000,000      | 10% at TGE, 12-month linear vesting                           |
| Airdrop           | 03 %                  | 3,000,000       | 50% at TGE, 12-month linear vesting                           |
| Reserve Fund      | 02 %                  | 2,000,000       | Locked for 24 months, 12-month vesting                        |

## Token Price

The token will have a price of 0,00001 ether, 10000000000000 wei, 0.026 dollars per coin.

## Airdrop Allocation

The TGE will be done the 25 of december, and 1000 tokens will be granted to every user that joins the whitelist. 50% of those tokens (500) will be available at the airdrop in 25 of dec, the rest of them will be vested over a 12 month period
