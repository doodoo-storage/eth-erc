// SPDX-License-Identifier: MIT
pragma solidity ^0.5.6;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
contract ERC721URIStorage is ERC721 {
  using Strings for uint256;

  mapping(uint256 => string) private _tokenURIs;

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];
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
    _tokenURIs[tokenId] = _tokenURI;
  }

  function _burn(uint256 tokenId) internal {
    super._burn(tokenId);

    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}