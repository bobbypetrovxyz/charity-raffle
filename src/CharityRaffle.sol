// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "./VRFConsumerBaseV2PlusCustom.sol";

contract CharityRaffle is OwnableUpgradeable, VRFConsumerBaseV2PlusCustom {
    uint256 public constant DENOMINATOR = 10000; // 100% in basis points
    uint256 public ticketPrice;
    uint256 public numOfWinners;
    uint256 public pricePersentageBPS;
    address public charityWallet;
    uint256 public vrfSubsciptionId;
    bytes32 public vrfKeyHash;
    uint256 public vrfRequestId;
    bytes32 public merkleRoot;

    uint256 public winnerReward;
    uint256 public charityFunds;

    address[] public participants;
    mapping(address => bool) public winners;
    bool public winnersSelected;

    event WinnersSelected(address[] winners);
    event TicketPurchased(address indexed buyer, uint256 quantity);
    event RandomnessRequested(uint256 requestId);
    event PrizeClaimed(address indexed winner);
    event CharityWithdrawal(uint256 amount);

    error InsufficientValue();
    error InvalidProof();
    error VRFRequestAlreadyMade();
    error InvalidRequest();
    error InvalidRandomWords();
    error NotAWinner();
    error TransferFailed();
    error InsufficientFunds();
    error WinnersNotSelected();
    error InsufficientContractBalance();
    error CharityWalletNotSet();

    function initialize(
        address _owner,
        address _charityWallet,
        uint256 _vrfSubsciptionId,
        bytes32 _vrfKeyHash,
        bytes32 _merkleRoot
    ) public initializer {
        __Ownable_init(_owner);
        s_vrfCoordinator = IVRFCoordinatorV2Plus(
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        ); // Set the VRF Coordinator address for Sepolia
        ticketPrice = 0.001 ether; // Set a default ticket price
        numOfWinners = 2; // Set a default number of winners
        pricePersentageBPS = 3000; // Set a default percentage for the prize pool
        charityWallet = _charityWallet;
        vrfSubsciptionId = _vrfSubsciptionId;
        vrfKeyHash = _vrfKeyHash;
        merkleRoot = _merkleRoot;
    }

    function buyTicket(uint256 _qty, bytes32[] memory _proof) external payable {
        require(msg.value == ticketPrice * _qty, InsufficientValue());

        bytes32 leaf = keccak256(abi.encode(msg.sender));
        require(
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(leaf))
            ),
            InvalidProof()
        );

        for (uint256 i = 0; i < _qty; i++) {
            participants.push(msg.sender);
        }

        emit TicketPurchased(msg.sender, _qty);
    }

    function requestRandomWinners() external onlyOwner {
        require(vrfRequestId == 0, VRFRequestAlreadyMade());
        vrfRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: vrfKeyHash,
                subId: vrfSubsciptionId,
                requestConfirmations: 3,
                callbackGasLimit: 1000000,
                numWords: uint32(numOfWinners),
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        uint256 fundsCollected = participants.length * ticketPrice;
        winnerReward = (fundsCollected * pricePersentageBPS) / DENOMINATOR;
        charityFunds = fundsCollected - (winnerReward * numOfWinners);

        emit RandomnessRequested(vrfRequestId);
    }

    function owner()
        public
        view
        override(OwnableUpgradeable, VRFConsumerBaseV2PlusCustom)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        require(requestId == vrfRequestId, InvalidRequest());
        require(randomWords.length == numOfWinners, InvalidRandomWords());

        address[] memory winnersArray = new address[](numOfWinners);

        for (uint256 i = 0; i < numOfWinners; i++) {
            uint256 randomWord = randomWords[i];

            while (true) {
                uint256 winnerIndex = randomWord % participants.length;
                address winner = participants[winnerIndex];

                if (!winners[winner]) {
                    winners[winner] = true;
                    winnersArray[i] = winner;
                    break;
                }

                randomWord = (randomWord + 1) % type(uint256).max; // Increment to find a new winner
            }

            winnersSelected = true;

            emit WinnersSelected(winnersArray);
        }
    }

    function claimPrize() external {
        require(winners[msg.sender], NotAWinner());
        require(
            address(this).balance >= winnerReward,
            InsufficientContractBalance()
        );

        winners[msg.sender] = false; // Prevent double claiming
        (bool success, ) = payable(msg.sender).call{value: winnerReward}("");
        require(success, TransferFailed());

        emit PrizeClaimed(msg.sender);
    }

    function claimCharityFunds() external onlyOwner {
        require(charityFunds > 0, InsufficientFunds());
        require(winnersSelected, WinnersNotSelected());
        require(
            address(this).balance >= charityFunds,
            InsufficientContractBalance()
        );
        require(charityWallet != address(0), CharityWalletNotSet());

        (bool success, ) = payable(charityWallet).call{value: charityFunds}("");
        require(success, TransferFailed());
        charityFunds = 0; // Reset charity funds after claiming

        emit CharityWithdrawal(charityFunds);
    }
}
