Green-Pluto project:

A social hybrid betting-trading game where AI trading algos compete for profit and users bet on algos

---

Solidity smart contract has been deployed to:
1) Goerli: https://goerli.etherscan.io/address/0x1ec8fed9ece227708bb4e93f632898cd590ae84e with Uniswap support
* For subgraph Goerli: https://goerli.etherscan.io/address/0x275f94e9261017cffa4636d86027ce9DbaacB5A8 without Uniswap support, mock instead
2) Polygon: https://polygonscan.com/address/0xC26fEB919867c5cb2e52f055902dB77250b73321
3) Optimism: https://optimistic.etherscan.io/address/0xf90AE1653Bcc5883E8652ff2cAA9465A443d7662
4) Scroll: https://blockscout.scroll.io/address/0x8fed78378216645fe64392acBaBa0e8c0114c875

Front-end has been deployed to:
https://green-pluto-3w.vercel.app/

Sponsor judging:

* The Qraph: Subgraph created and deployed and available at:
https://api.studio.thegraph.com/query/46807/green-pluto-subgraph/v0.1

* zkBob:
zkBob address generated: zkbob_polygon:HPbCiohP8Lb4rvXmY1FHAWrMVjqTo6v6BShNWhzaWWCf5AvzRFj5D2HkeWonyCU

* Polygon: polygon deployment made, see deployment addresses:
https://polygonscan.com/address/0xC26fEB919867c5cb2e52f055902dB77250b73321
and tweet:
https://twitter.com/WarpPluto/status/1657548037575655432

* Scroll: scroll deployment made, see deployment addresses:
https://blockscout.scroll.io/address/0x8fed78378216645fe64392acBaBa0e8c0114c875

* Worldcoin: Worldcoin widget was added to front-end, since this may be a game with restrictions in many juristications.
Unfortunately it was not possible to obtain the app_id and thus the widget: <IDKitWidget /> does not show up in frontend althoug necessary code is added

* 1inch: your product fits well as a complement to players to swap their tokens to play the game (place bets), or
for certain cases for Algo providers to compete with the algos and get the best prices.
Tried to add a widget/component in frontend for users to swap, but didn't make it to full integration and removed from the last version (left the button though)

* Optimism: optimism deployment made (truncuated code due to cost restraints), see deployment addresses:
Optimism: https://optimistic.etherscan.io/address/0xf90AE1653Bcc5883E8652ff2cAA9465A443d7662

---

Description of the project:

This is a social platform which allows users to make bets on AI algos. Algo trading competition gamifies and socializes trading,

Algo providers compete with their best algos to make profit for the users. Users bet on algos and always earn algo profits. In addition to algo profits, backers of the winning algo get back their bet principle and divide the pool of other losing bets. If all algos are profitable, everybody gets back at least something. But choosing the winning algo can offer magnificent returns.

So this is a hybrid of trading and betting which is at the same time gamified and enables users to share their thoughts and follow the process of algo trading as if watching race horses. But this time it is like a financial derivative, somewhat similar to binary derivatives but more user friendly and entertaining. 

The chairperson (set in the smart contract by the contract owner) assigns algo providers who will use off-chain (current implementation) or on-chain computations to make trades with predetermined assets. Allowed assets are fixed in the contract and every algo uses the same asset. Algo providers must stake some assets to be eligible to manage the algos and assets assigned to algos.

Users deposit funds into the contract and can bet on algos. The chairperson starts the betting period and ends the betting period (can be automated in later implementations based on epochs). After the betting period ends, algo providers get access to funds which have been bet on their algos. The aim of the algo providers is to earn as much as possible during the trading period. After the trading period ends, the chairperson announces the winner (oracle can be used for that in later implementations) and posts the returns. Everybody gets their returns if positive. If negative, this will decrease the winners' pool which will be proportionally divided by all players who bet on the winning algo.

In essence, the game resembles a gambling game but if algos pools will be tokenized or those will emit NFT-s as a representation of the algo share, the game can be viewed as a new type of financial derivative instead. It will even be possible to hedge some of the losses. Always getting the algo profit can make it potentially more interesting and appealing to users.

