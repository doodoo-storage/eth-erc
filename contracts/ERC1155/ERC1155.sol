// SPDX-License-Identifier: MIT
pragma solidity ^0.5.6;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";
import "../introspection/ERC165.sol";
import "../introspection/IERC165.sol";
import "hardhat/console.sol";

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
  using Address for address;

  mapping(uint256 => mapping(address => uint256)) private _balances;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  string internal _uri;

  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  /** bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) */
  bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61;

  /** bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")) */
  bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81;

  event BeforeTransfer(address operator, address from, address to, uint256[] ids, uint256[] amounts, bytes data);

  constructor(string memory uri_) public {
    _setURI(uri_);
    _registerInterface(INTERFACE_SIGNATURE_ERC165);
    _registerInterface(INTERFACE_SIGNATURE_ERC1155);
  }

  function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
    if (_interfaceId == INTERFACE_SIGNATURE_ERC165 || _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
      return true;
    }

    return false;
  }

  /** 해당 token의 uri를 조회 */
  function uri(uint256) public view returns (string memory) {
    return _uri;
  }

  /** account의 해당 tokenId의 balance를 조회 */
  function balanceOf(address account, uint256 id) public view returns (uint256) {
    require(account != address(0), "ERC1155: balance query for the zero address");
    return _balances[id][account];
  }

  /** 
   * accounts의 해당 tokensIds의 balance를 조회 
   * index로 matching되므로 length가 같아야만 한다.
  */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
    require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /** operator에게 msgSender의 token들에 대한 전송 권한에 대해 설정 */
  function setApprovalForAll(address operator, bool approved) public {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /** operator의 전송 권한을 확인 */
  function isApprovedForAll(address account, address operator) public view returns (bool) {
    return _operatorApprovals[account][operator];
  }

  /** from의 id에 해당하는 token을 amount만큼 to에게 전송 */
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public {
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );
    _safeTransferFrom(from, to, id, amount, data);
  }
  
  /** from의 ids에 해당하는 token들을 amount들만큼 to에게 전송 */
  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public {
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      "ERC1155: transfer caller is not owner nor approved"
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /**
   * _asSingletoneArray => uint256 id를 array로 변환해주는 함수
   * _doSafeTransferAcceptanceCheck => token을 받는 대상이 contract라면 safeTransferFrom이 구현되어있는지를 확인하는 함수
   */
  function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal {
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();
    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
    _balances[id][from] = fromBalance - amount;
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
      _balances[id][from] = fromBalance - amount;
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }
  
  function _setURI(string memory newuri) internal {
    _uri = newuri;
  }
  
  function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
    require(to != address(0), "ERC1155: mint to the zero address");
    
    address operator = _msgSender();
    _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);
    _balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);
    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = _msgSender();
    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);
    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  function _burn(address from, uint256 id, uint256 amount) internal {
    require(from != address(0), "ERC1155: burn from the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
    _balances[id][from] = fromBalance - amount;
    

    emit TransferSingle(operator, from, address(0), id, amount);
  }

  function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal {
    require(from != address(0), "ERC1155: burn from the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
      _balances[id][from] = fromBalance - amount;
    }

    emit TransferBatch(operator, from, address(0), ids, amounts);
  }

  function _setApprovalForAll(address owner, address operator, bool approved) internal {
    require(owner != operator, "ERC1155: setting approval status for self");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
    emit BeforeTransfer(operator, from, to, ids, amounts, data);
  }

  function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private returns (bool) {
    if (!to.isContract()) { return true; }
    
    require(IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) == ERC1155_ACCEPTED, "ERC1155: contract returned an unknown value from onERC1155Received");
    return true;
  }

  function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private returns (bool) {
    if (!to.isContract()) { return true; }
    
    require(IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) == ERC1155_BATCH_ACCEPTED, "ERC1155: contract returned an unknown value from onERC1155BatchReceived");
    return true;
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}