import { expect } from 'chai';
import { ethers } from 'hardhat';
import { ERC1155Token } from '../../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

describe('ERC1155Token', () => {
  let token: ERC1155Token;
  let accounts: SignerWithAddress[];
  
  const tokenURI = '';

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    const Token = await ethers.getContractFactory('ERC1155Token');
    token = await Token.deploy(tokenURI);
    await token.deployed();
  });

  it('Create function must be able to mint itself only to the msg sender', async () => {
    const initSupply = 1000;
    const customURI = '';
    
    console.log(await token.balanceOf(accounts[0].address, 1));
    await expect(token.create(initSupply, customURI)).to.be.emit(token, 'URI');

    const tokenId = await token.getCurrentTokenId();
    const createdURI = await token.uri(tokenId);

    expect(createdURI).to.not.equal(tokenURI);
    expect(createdURI).to.equal(customURI);
  });

  it('When minting, setting the uri should return a custom uri', async () => { 
    const initSupply = 1000
    const customURI = '';

    const createTx = await token.create(initSupply, customURI);
    await createTx.wait();

    const tokenId = await token.getCurrentTokenId();

    const uri = await token.uri(tokenId);
    expect(uri).to.equal(customURI);
  });

  it('When minting, if the length of _toList and _values ​​is not the same, they must be reverted', async() => {
    const addresses = accounts.map(account => account.address).slice(0, 2);
    const values = new Array(4).fill(100);

    await expect(token.mintToList(addresses, values)).to.be.revertedWith('ERC1155: toList and _values length mismatch');
  });

  it('When minting, if _toList and _values ​​have the same length, mint should be executed success', async () => {
    const addresses = accounts.map(account => account.address).slice(0, 2);
    const values = new Array(2).fill(100);

    const mintTx = await token.mintToList(addresses, values);
    await mintTx.wait();
    
    const tokenId = await token.getCurrentTokenId();

    expect(await token.balanceOf(addresses[0], tokenId)).to.equal(values[0]);
    expect(await token.balanceOf(addresses[1], tokenId)).to.equal(values[1]);
  });

  it('When mintBatch is called, multiple tokens must be minted', async () => {
    const [mintUser] = accounts;
    const values = new Array(2).fill(100);
    const tokenIds = [1, 2];

    const mintTx = await token.mintBatch(mintUser.address, values);
    await mintTx.wait();

    const addresses = new Array(2).fill(mintUser.address);
    const balances = await token.balanceOfBatch(addresses, tokenIds);

    for (let i = 0; i < tokenIds.length; i++) {
      expect(values[i]).to.equal(balances[i]);
    }
  });

  it('After calling setApprovalAll, the value of isApprovedForAll must be changed', async () => {
    const [mintUser, approveUser] = accounts;

    const mintTx = await token.connect(mintUser).mint(mintUser.address, 10);
    await mintTx.wait();

    await expect(token.connect(mintUser).setApprovalForAll(mintUser.address, true)).to.be.revertedWith('ERC1155: setting approval status for self');
    await expect(token.connect(mintUser).setApprovalForAll(approveUser.address, true)).to.emit(token, 'ApprovalForAll')
      .withArgs(mintUser.address, approveUser.address, true);

    expect(await token.isApprovedForAll(mintUser.address, approveUser.address)).to.equal(true);
  });
})