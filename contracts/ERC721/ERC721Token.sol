// SPDX-License-Identifier: Handstudio
pragma solidity ^0.5.6;

import "./ERC721.sol";
import "./extensions/ERC721URIStorage.sol";
import "../utils/Counters.sol";
import "../utils/Context.sol";

contract ERC721Token is ERC721 {

  using Strings for uint256;

  mapping(uint256 => string) private _uris;
  
  using Counters for Counters.Counter;
  
  Counters.Counter private _tokenIds;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) public {}

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    string memory _tokenURI = _uris[tokenId];
    string memory base = _baseURI();

    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    return super.tokenURI(tokenId);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
    require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    _uris[tokenId] = _tokenURI;
  }

  function mint(string memory uri) public returns (uint256) {
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    _mint(msg.sender, newItemId);
    _setTokenURI(newItemId, uri);
    
    return newItemId;
  }

  function getCurrentTokenId() public view returns (uint256) {
    return _tokenIds.current();
  }
}