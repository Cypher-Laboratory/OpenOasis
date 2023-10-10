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
    mapping(string => Status) public mintStatus; // signatureHash => Status (computed off-chain)

    constructor(address _verifier) ERC721("AliceRingToken", "ART") Ownable() {
        verifier = RingSignatureVerifier(_verifier);
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice safeTransferFrom is disabled because the nft is a sbt
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert("SBT: SafeTransfer not allowed");
    }

    /**
     * @notice transferFrom is disabled because the nft is a sbt
     */
    function transferFrom(address from, address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert("SBT: Transfer not allowed");
    }

    /**
     * @notice approve is disabled because the nft is a sbt and cannot be transferred
     */
    function approve(address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert("SBT: Approve not allowed");
    }

    /**
     * @notice getApproved is disabled because the nft is a sbt and cannot be transferred
     */
    function getApproved(uint256 tokenId) public pure override(ERC721, IERC721) returns (address operator) {
        revert("SBT: getApproved not allowed");
    }

    /**
     * @notice setApprovalForAll is disabled because the nft is a sbt and cannot be transferred
     */
    function setApprovalForAll(address operator, bool _approved) public pure override(ERC721, IERC721) {
        revert("SBT: setApprovalForAll not allowed");
    }

    /**
     * @notice isApprovedForAll is disabled because the nft is a sbt and cannot be transferred -> the output will always be false
     */
    function isApprovedForAll(address owner, address operator) public pure override(ERC721, IERC721) returns (bool) {
        return false;
    }

    /**
     * @notice Verifies the token amounts for each address in the ring
     *
     * @param token - the erc20 address of the token we are proving the ownership of
     * @param minBalance -  the minimum balance of this token required by an address
     * @param signature - the signature object
     */
    function verifyTokenAmounts(address token, uint256 minBalance, Signature memory signature)
        internal
        view
        returns (bool)
    {
        // Check that all addresses in the ring own at least the minimal amount of tokens specified
        IERC20 tokenContract = IERC20(token);
        for (uint256 i = 0; i < signature.ring.length; i++) {
            pubKey memory key = signature.ring[i];
            address ringMember = address(uint160(uint256(keccak256(abi.encodePacked(key.x, key.y)))));
            if (tokenContract.balanceOf(ringMember) < minBalance) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Mint an SBT
     *
     * The sbt is minted to msg.sender
     * If the verification of the signature is okay see (https://github.com/Cypher-Laboratory/EVM-Verifier/issues/3) and :
     * - If `mintStatus[proofId] == UNKNOWN`, the proof is minted and the status is set to `MINTED`
     * - If `mintStatus[proofId] == MINTED`, the proof has already been minted. Tx will revert
     *
     * @param token - the erc20 address of the token we are proving the ownership of
     * @param minBalance - the balance threshold
     * @param signature - the signature object
     * @param uri - the IPFS uri
     * @param proofId - the hash of all the responses used in the proof
     */
    function mint(
        address token,
        uint256 minBalance,
        Signature memory signature,
        string memory uri,
        string memory proofId
    ) public payable {
        if (mintStatus[proofId] == Status.MINTED) {
            revert AlreadyMinted(proofId);
        }
        if (!verifier.verify("DummySignature")) {
            revert InvalidSignature();
        }
        if (!verifyTokenAmounts(token, minBalance, signature)) {
            revert InvalidTokenAmounts();
        }
        mintStatus[proofId] = Status.MINTED;
        _safeMint(msg.sender, _nextTokenId);
        _setTokenURI(_nextTokenId, uri);
        _nextTokenId++;
    }

    /**
     * @notice delete all the caracteristics of tokenId (burn)
     *
     * Only the owner of an sbt can burn it
     *
     * @param tokenId is the id of the sbt to burn
     */
    function burn(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert OnlyOwnerCanBurn(tokenId);
        }
        _burn(tokenId);
    }

    // Override the _burn function from ERC721
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
