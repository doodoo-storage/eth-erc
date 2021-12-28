pragma solidity ^0.5.6;

import "./ERC1155.sol";
import "../utils/Counters.sol";
import "../utils/Context.sol";
import "hardhat/console.sol";

contract ERC1155Token is Context, ERC1155 {

  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  mapping(uint256 => address) public creators;
  mapping(uint256 => string) _uris;

  constructor (string memory uri) public ERC1155(uri) {}

  function _exists(uint256 tokenId) internal view returns (bool) {
    address creator = creators[tokenId];
    return creator != address(0);
  }

  /** 
   * token별로 설정한 url이 있다면 해당 url return 
   * 없다면 ERC1155에 설정한 _uri variable return
   */
  function uri(uint256 tokenId) public view returns (string memory) {
    string memory customURI = string(_uris[tokenId]);
    if(bytes(customURI).length != 0) {
      return customURI;
    }

    return _uri;
  }

  function getCurrentTokenId() public view returns (uint256) {
    return _tokenIds.current();
  }

  /**
   * msg sender가 mint할 수 있는 함수
   * 초기 supply 설정 및 URI 설정
   */
  function create(uint256 _initialSupply, string memory _uri) public returns (uint256) {
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    creators[newItemId] = _msgSender();
    _mint(_msgSender(), newItemId, _initialSupply, "");
    
    if (bytes(_uri).length > 0) {
      _uris[newItemId] = _uri;
      emit URI(_uri, newItemId);
    }

    return newItemId;
  }

  /** 
   * 단일 토큰에 대한 mint 
   * TransferSingle event를 발생시켜야만 함
   */
  function mint(address _to, uint256 _value) public returns (uint256) {
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    _mint(_to, newItemId, _value, "");

    return newItemId;
  }

  /**
   * toList들에게 _values의 index와 맞춰 같은 id를 가진 토큰을 해당 values 만큼 mint
   * TransferSingle event를 발생시켜야만 함
   */
  function mintToList(address[] memory _toList, uint256[] memory _values) public {
    require(_toList.length == _values.length, "ERC1155: toList and _values length mismatch");

    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    for (uint256 i = 0; i < _toList.length; ++i) {
      address to = _toList[i];
      uint256 value = _values[i];
      _mint(to, newItemId, value, "");
    }
  }

  /**
   * 일괄 토큰 발급
   * TransferSingle 또는 TransferBatch 이벤트 발생시켜야만 함
   */
  function mintBatch(address _to, uint256[] memory _values) public {
    uint256[] memory ids = new uint256[](_values.length);
    
    for (uint256 i = 0; i < _values.length; ++i) {
      _tokenIds.increment();
      ids[i] = _tokenIds.current();
    }

    _mintBatch(_to, ids, _values, "");
  }
}