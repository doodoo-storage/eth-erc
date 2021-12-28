// SPDX-License-Identifier: MIT
pragma solidity ^0.5.6;

import "hardhat/console.sol";

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../introspection/ERC165.sol";


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  string private _name;
  string private _symbol;

  /** tokenId와 owner의 wallet address mapping */
  mapping(uint256 => address) private _owners;
  
  /** wallet address와 가지고 있는 token 갯수의 mapping */
  mapping(address => uint256) private _balances;
  
  /** tokenId와 approved 받은 user의 address mapping */
  mapping(uint256 => address) private _tokenApprovals;
  
  /** user => user의 approval flag mapping */
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
    * bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")) = 0x150b7a02
    * IKIP17Receiver(0).onERC721Received.selector return value 
    */
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  constructor(string memory name_, string memory symbol_) public {
    _name = name_;
    _symbol = symbol_;
  }

  /** interface에 명시된 function들에 대한 구현을 확인 */
  function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /** owner에 대한 해당 token의 balance 조회 */
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  /** tokenId로 해당 token의 owner 조회 */
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /** token의 이름 조회 */
  function name() public view returns (string memory) {
    return _name;
  }

  /** token의 symbol 조회 */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /** tokenId로 해당 token의 url 조회 */
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function _baseURI() internal pure returns (string memory) {
    return "";
  }

  /** to에게 해당 token의 권한을 넘김 */
  function approve(address to, uint256 tokenId) public {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");
    require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

    _approve(to, tokenId);
  }

  /** 해당 token에 대한 권한을 가진 address를 조회 */
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /** operator에게 msgSender의 전송 권한에 대해 설정*/
  function setApprovalForAll(address operator, bool approved) public {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /** operator의 전송 권한을 확인 */
  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /** from의 token을 to에게 전송 */
  function transferFrom(address from, address to, uint256 tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721L transfer caller is not owner not approved");

    _transfer(from, to, tokenId);
  }

  /**
    * 다른 contract로 token을 전송할 때 사용
    * onERC721Received를 구현해놓은 contract여야만 전송 가능
    */
  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /** 해당 tokenId의 owner가 존재하는지에 대한 확인 */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  /** spender가 해당 token의 관리 권한을 가지고 있는지에 대한 조회 */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, "");
  }

  function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
    _mint(to, tokenId);
    require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /** token 발행 */
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
  }

  /**  
   * to의 address가 contract가 아닌 지갑주소라면 true를 return
   * 만약 to의 주소가 contract라면 to의 contract에 safeTransfer를 위한 Receiver가 구현되어 있는지를 확인
   * deprecated
  */
  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
    if (!to.isContract()) { return true; }
    
    (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
      IERC721Receiver(to).onERC721Received.selector,
      _msgSender(),
      from,
      tokenId,
      _data
    ));
    
    if (!success) {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert("ERC721: transfer to non ERC721Receiver implementer");
      }
    } else {
      bytes4 retval = abi.decode(returndata, (bytes4));
      return (retval == _ERC721_RECEIVED);
    }
  }

  function _burn(uint256 tokenId) internal {
    address owner = ERC721.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);
    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(address from, address to, uint256 tokenId) internal {
    require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
  }

  function _setApprovalForAll(address owner, address operator, bool approved) internal {
    require(owner != operator, "ERC721: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    
    emit ApprovalForAll(owner, operator, approved);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {}

}