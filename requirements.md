## Decentralized Charity Raffle
A non-profit organization wants to run a transparent, on-chain raffle to raise donations while fairly rewarding participants. Eligible users can buy tickets, and after the raffle ends, a set of winners is randomly selected. A portion of the collected funds is awarded as prizes, and the rest is donated to the charity.

Create a Solidity Smart Contract system where:
-	Donors purchase raffle tickets.
-	Only addresses on an allow-list may buy tickets (e.g. KYC'd supporters, partners).
-	After the sales deadline, winners are drawn with Chainlink VRF.
-	Part of the ETH proceeds are forwarded to the charity’s treasury.

### Project Structure
Students may use Foundry only, or Foundry + Hardhat project setup. OpenZeppelin or similar libraries are allowed.

## Detailed Business and Technical Requirements
### System Overview
The "Charity Raffle" system consists of a single **upgradeable** contract exposed through an **OpenZeppelin Transparent Proxy**. The proxy architecture guarantees that storage lives forever, while logic can be patched if auditors discover an issue or the charity wishes to add new game modes in the future.

### Lifecycle & User Journeys
1.	**Initialization**
The developer invokes a deployment script that:
-	Deploys the implementation.
-	Deploys a TransparentUpgradeableProxy pointing at that implementation.
-	Calls initialize on the proxy to set:
>-	ticket price - 0.001 ETH
>-	number of winners - 2
>-	percentage of raffle funds to allocate for Prize - 30%
>-	charity treasury wallet.
>-	Chainlink VRF subscription
>-	Chainlink VRF keyHash
>-	merkle root
Note: After initialization, none of those parameters may change; the charity would have to deploy a new raffle for a new campaign.

2.	**Ticket Sale**
-	Supporters submit buyTickets(qty, merkleProof) with msg.value == qty * ticketPrice.
-	The contract verifies the Merkle proof to confirm eligibility.
-	For each ticket, the buyer’s address is stored in an internal list (array).

Business note: An address may buy as many tickets as desired; each ticket is an independent entry in the draw.

3.	**Draw Request**
-	Once the owner decides, he can trigger the requestRandomWinners( method).
-	This action finishes the ticket sale phase.
-	It records a VRF request ID.
-	It calculates the portion per winner of the prize pool. **(prizePoolBPS / 10_000 represents the percentage of total funds that must be allocated to the prize pool)**
-	The function can only be called once.
-	Can be called only by the owner.

4.	**Randomness Fulfilment**
-	Chainlink VRF invokes fulfillRandomWords.
-	The callback derives unique winner indices (randomWords[0], randomWords[1], …) until the required numWinners distinct positions are produced.
-	Corresponding addresses are recorded as winners, and an event announces the draw outcome.
-	Ensure the right request is triggered
-	Ensure proper random words length
-	Ensure same winner can’t be chosen twice

5.	**Prize Claim**
-	Each winner may independently call claimPrize() once the winners are chosen.
-	The contract calculates prizeShare based on prizePool and winners count and transfers it.

6.	**Charity Withdrawal**
-	After the winners are selected, the charity owner can call withdrawCharity() to collect the funds allocated for the charity.
-	Funds go to the pre-defined charityTreasury wallet.

### Roles & Permissions
1.	**Owner** - Triggers Draw Request; withdraw charity share, upgrade logic via proxy admin.
2.	**Buyer** - Purchase tickets while the sale is open and the whitelist proof is valid.
3.	**Winner** - Claim prize.
4.	**Chainlink Coordinator** - Fulfil randomness.

### Key Business Rules
- **No refunds** – All ticket purchases are final.
- **Single draw** – Exactly one randomness request per raffle instance.
- **Equal prizes** – Each winner receives the same ETH amount.
- **Transparency** – All critical actions (TicketsPurchased, RandomnessRequested, WinnersSelected, PrizeClaimed, CharityWithdrawal) must emit events to support public monitoring.

### Simplified Assumptions
1.	**Ticket economics**
- a.	Price is constant and set once when the contract is initialized.
- b.	The number of winners (numWinners) and the prize split (prizeBps in basis points) are also frozen at initialization.

2.	**Eligibility** – Only addresses included in a Merkle-tree allow-list may buy tickets. The Merkle root is published up front and never changes.

3.	**Prizing** – The prize pool is simply ETH already held by the contract; there is no additional token distribution. Winnings are paid in equal portions to each winner for clarity.

4.	**Randomness** – Chainlink VRF (Sepolia) provides the randomness. During local testing, students may mock the VRFCoordinator for easier testing.

5.	**Minimum Participation**
- a.	For simplicity, there is no enforcement of a minimum number of participants.
- b.	It is assumed that the number of participants will always be sufficient (e.g., at least twice the number of winners), and the contract does not protect against edge cases like insufficient entries.

## General Requirements
### Merkle Tree Allowlist
-	Use a Merkle-tree allow-list to restrict who can purchase raffle tickets.
-	A script for generating the Merkle tree and proofs must be included in the project submission.
-	The script should generate a merkle_data.json file containing:
-	The Merkle root
-	An array of test participants, each with their corresponding Merkle proof
-	The merkle_data.json file must be included in the final submission.
-	Use this data to test the contract on Sepolia.

### Upgradeability
Implement via TransparentUpgradeableProxy.

### Oracles
Use Chainlink VRF to choose random winners.
NOTE: VRFConsumerBaseV2PlusCustom.sol contract is provided in the resources to be used as a base for your implementation.

### Proper Implementation of Key Business Requirements & Roles
Your solution must fully adhere to the described business logic and roles

## Other Requirements
### Manual testing on Sepolia
Proof you've manually tested all key steps of the process by adding deployments addresses and executed transaction info in the README.md file (More info in the Project Submission section).

### Security and Gas Optimization
Apply the security principles and gas optimization techniques covered in the course.

### Project Submission
Submit a .zip of the entire Foundry/Hardhat project, excluding node_modules, coverage, artifacts, cache, out, and the lib folder. If libraries (in lib folder as submodules)  other than:
- forge-std
- OpenZeppelin/openzeppelin-contracts
- OpenZeppelin/openzeppelin-contracts-upgradeable
- OpenZeppelin/openzeppelin-foundry-upgrades
- smartcontractkit/chainlink-brownie-contracts
have to be installed, specify in the README.md under the Additional Packages category.

Include a README.md in the root project directory explaining:
-	How to install and run tests (if any)
-	The deployment and verification steps
-	The verified contract links on Etherscan, together with Etherscan links for at least one transaction for every important business step <give an exact format>
 
### Assessment Criteria
1. General Requirements (70%)
2. Other Requirements (30%)

Deliver an upgrade-ready, Merkle-gated raffle that draws multiple winners via Chainlink VRF, splits funds transparently, and proves the flow with a single Foundry test. Build it cleanly, secure it carefully—then let the good cause benefit. Good luck!

### Hints
If you want to test your contract locally, use a mocked VRF implementation to simulate Chainlink VRF behavior.
