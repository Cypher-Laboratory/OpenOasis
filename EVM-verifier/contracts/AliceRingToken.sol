// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RingSignatureVerifier {
    constructor() {}

    function verify(string memory signature) public pure returns (bool) {
        return true;
    }
}

contract AliceRingToken is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    struct pubKey {
        uint256 x;
        uint256 y;
    }

    struct Signature {
        pubKey[] ring;
        uint256 c;
        string message;
        uint256[] responses;
    }

    enum Status {
        UNKNOWN, // the proof has not been verified on-chain, no proof has been minted
        MINTED // the proof has already been minted
    }

    error AlreadyMinted(string proofId);
    error InvalidSignature();
    error InvalidTokenAmounts();
    error OnlyOwnerCanBurn(uint256 tokenId);

    RingSignatureVerifier public verifier; // Instance of the ring signature verifier contract
    uint256 public minimalAmount; // Minimal amount of tokens to be owned by each address in the ring

    mapping(string => Status) public mintStatus; // signatureHash => Status (computed off-chain)

    constructor(address initialOwner, address _verifier, uint256 _minimalAmount)
        ERC721("AliceRingToken", "ART")
        Ownable(initialOwner)
    {
        verifier = RingSignatureVerifier(_verifier);
        minimalAmount = _minimalAmount;
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function approve(address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert("SBT: Approve not allowed");
    }

    function getApproved(uint256 tokenId) public pure override(ERC721, IERC721) returns (address operator) {
        revert("SBT: getApproved not allowed");
    }

    function setApprovalForAll(address operator, bool _approved) public pure override(ERC721, IERC721) {
        revert("SBT: setApprovalForAll not allowed");
    }

    function isApprovedForAll(address owner, address operator) public pure override(ERC721, IERC721) returns (bool) {
        return false;
    }

    function verifyTokenAmounts(address token, Signature memory signature) internal returns (bool) {
        // Check that all addresses in the ring own at least the minimal amount of tokens specified
        IERC20 tokenContract = IERC20(token);
        for (uint256 i = 0; i < signature.ring.length; i++) {
            pubKey memory key = signature.ring[i];
            address ringMember = address(uint160(uint256(keccak256(abi.encodePacked(key.x, key.y)))));
            if (tokenContract.balanceOf(ringMember) < minimalAmount) {
                return false;
            }
        }
        return true;
    }

    function mint(address token, Signature memory signature, string memory uri, string memory proofId) public payable {
        if (mintStatus[proofId] == Status.MINTED) {
            revert AlreadyMinted(proofId);
        }
        if (!verifier.verify("DummySignature")) {
            revert InvalidSignature();
        }
        if (!verifyTokenAmounts(token, signature)) {
            revert InvalidTokenAmounts();
        }
        mintStatus[proofId] = Status.MINTED;
        _safeMint(msg.sender, _nextTokenId);
        _setTokenURI(_nextTokenId, uri);
        _nextTokenId++;
    }

    function burn(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert OnlyOwnerCanBurn(tokenId);
        }
        _burn(tokenId);
    }
}
