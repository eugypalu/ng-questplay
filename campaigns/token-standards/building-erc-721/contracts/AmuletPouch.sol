// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC721.sol";
import "./interfaces/IAmuletPouch.sol";
import "./Amulet.sol";

/**
 * @dev ERC-721 Token Receiver token contract.
 */
contract AmuletPouch is IAmuletPouch {

    struct Request {
        address requester;
        uint256 tokenId;
        uint256 requestedTokenId;
        uint256 votes;
        bool processed;
        mapping(address => bool) voters;
    }
    Amulet public amulet;
    uint256 requestId = 0;
    uint256 totalMembersCounter = 0;

    mapping (address => bool) members;
    mapping(uint256 => Request) requests;

    constructor(address _amulet) {
        amulet = Amulet(_amulet);
    }

    function voteFor(uint256 _requestId) external {
        require(members[msg.sender], "Not a member");
        require(requests[_requestId].requester != address(0), "wrong request");
        require(!requests[_requestId].processed, "Request already processed");
        require(!requests[_requestId].voters[msg.sender], "Already voted");
        requests[_requestId].votes++;
        requests[_requestId].voters[msg.sender] = true;
    }

    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }

    function totalMembers() external view returns (uint256) {
        return totalMembersCounter;
    }

    function withdrawRequest(uint256  _requestId) external view returns (address, uint256) {
        return (requests[_requestId].requester, requests[_requestId].requestedTokenId);
    }

    function numVotes(uint256  _requestId) external view returns (uint256) {
        return requests[_requestId].votes;
    }

    function withdraw(uint256 _requestId) external {
        require(requests[_requestId].requester == msg.sender, "Not requester");
        if (requests[_requestId].votes >= totalMembersCounter / 2) {
            requests[_requestId].processed = true;
            amulet.safeTransferFrom(address(this), requests[_requestId].requester, requests[_requestId].requestedTokenId);
        }    
        require(requests[_requestId].processed, "Request not processed");
    }

    function onERC721Received(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes calldata _data
    ) external returns (bytes4) {
        require(msg.sender == address(amulet), "Only Amulet tokens are accepted");
        members[from] = true;
        totalMembersCounter++;
        if (_data.length > 0) {
            uint256 requestedId = abi.decode(_data, (uint256));
            Request storage request = requests[requestId];
            request.requester = from;
            request.tokenId = tokenId;
            request.requestedTokenId = requestedId;
            request.votes = 1;
            request.processed = false;
            emit WithdrawRequested(from, requestedId, requestId);
            requestId++;    
        }
        return this.onERC721Received.selector;
    }
}