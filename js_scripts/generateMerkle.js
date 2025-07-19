const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");

const participants = [
    "0xf9681Cb4b3Fd6ea3512BAfADCDcb25be41affc7a",
    "0x87C481a4934df1C57Fe4Cd9833bDF28bDa96b20D",
    "0x38234f5C88F0d1CcC5b85D4Da6805E6E243a8cBc",
    "0xF38EAC99B2eB75d39De3886001D9a453934F8a01"
];

const values = participants.map((participant) => [participant]);
const tree = StandardMerkleTree.of(values, ["address"]);

const participantWithProof = participants.map((participant, index) => {

    return {
        address: participant,
        proof: tree.getProof(index)
    };
});

const merkleData = {
    root: tree.root,
    participants: participantWithProof
};
fs.writeFileSync("merkle_data.json", JSON.stringify(merkleData));