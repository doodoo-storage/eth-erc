pragma solidity ^0.5.6;

import "../ERC721/ERC721Token.sol";
import "../ERC1155/ERC1155Token.sol";

contract ERCTokenFactory {
  mapping (string => ERC721Token) private erc721Tokens;
  mapping (string => ERC1155Token) private erc1155Tokens;

  event ERC721TokenCreate(address tokenAdderss, string name, string symbol);
  event ERC1155TokenCreate(address tokenAdderss, string uri);

  function createERC721Token(string memory creator, string memory name, string memory symbol) public {
    ERC721Token erc721Token = new ERC721Token(name, symbol);
    erc721Tokens[creator] = erc721Token;
    
    emit ERC721TokenCreate(address(erc721Token), name, symbol);
  }

  function createERC1155Token(string memory creator, string memory uri) public {
    ERC1155Token erc1155Token = new ERC1155Token(uri);
    erc1155Tokens[creator] = erc1155Token;

    emit ERC1155TokenCreate(address(erc1155Token), uri);
  }

  function getERC721TokenByCreator(string memory creator) public view returns(ERC721Token) {
    return erc721Tokens[creator];
  }

  function getERC1155TokenByCreator(string memory creator) public view returns(ERC1155Token) {
    return erc1155Tokens[creator];
  }
}