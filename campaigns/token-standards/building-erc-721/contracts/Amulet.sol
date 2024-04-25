// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721TokenReceiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev ERC-721 token contract.
 */
contract Amulet is IERC721, IERC721Metadata  {
    using Strings for uint256;
    string private _name;
    string private _symbol;
    uint256 private currentTokenId = 0;
    address contractOwner;

    mapping(uint256 tokenId => address) private _owners;

    mapping(address owner => uint256) private _balances;

    mapping(uint256 tokenId => address) private _tokenApprovals;

    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;
    
    mapping (uint256 => string) private _tokenURIs;

    constructor() {
        _name = "Amulet";
        _symbol = "AMULET";
        contractOwner = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, msg.sender);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert("ERC721InvalidOwner");
        }
        return _balances[owner];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert("ERC721InvalidReceiver");
        }
        address previousOwner = _update(to, tokenId, msg.sender);
        if (previousOwner != from) {
            revert("ERC721IncorrectOwner");
        }
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data));
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert("ERC721InvalidOperator");
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function mint(address _owner, string memory _uri) public returns (uint256) {
        require(msg.sender == contractOwner, "Only the contract owner can mint tokens");
        uint256 newTokenId = currentTokenId;
        _mint(_owner, newTokenId);
        _tokenURIs[newTokenId] = _uri;
        currentTokenId++;
        return newTokenId;
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert("ERC721InvalidReceiver");
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert("ERC721InvalidSender");
        }
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert("ERC721NonexistentToken");
        }
        return owner;
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        if (from != address(0)) {
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                _balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }


    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert("ERC721NonexistentToken");
            } else {
                revert("ERC721InsufficientApproval");
            }
        }
    }

    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert("ERC721InvalidApprover");
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function isContract(address _addr) private view returns (bool isContract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
