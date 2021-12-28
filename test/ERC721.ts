import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import { ERC721Token } from '../../typechain';

describe('KIP17Token', () => {
  let token: ERC721Token;
  let accounts: SignerWithAddress[];

  const tokenName = 'ERC721';
  const tokenSymbol = 'E721';
  const tokenURI = '';

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    
    const Token = await ethers.getContractFactory('ERC721Token');
    token = await Token.deploy(tokenName, tokenSymbol);
    await token.deployed();
  });

  it('Should return the new token, the symbol function return data must be tokenSymbol variable', async () => {  
    expect(await token.symbol()).to.equal(tokenSymbol);
  });

  it('Should return the new token, the name function return data must be tokenName variable', async () => {
    expect(await token.name()).to.equal(tokenName);
  });

  it('Shoule be calling  balanceOf, return balance by addres', async () => {
    const [mintUser] = accounts;

    await expect(token.balanceOf('0x0000000000000000000000000000000000000000')).
      to.be.revertedWith('ERC721: balance query for the zero address');
    
    await expect(token.mint(tokenURI)).to.emit(token, 'Transfer');
    expect(await token.balanceOf(mintUser.address)).to.equal(1);
  });

  it('Should be after mint the token, return owner id', async () => {
    const [mintUser] = accounts;

    const mintTx = await token.connect(mintUser).mint(tokenURI);
    await mintTx.wait();

    const currentTokenId = await token.getCurrentTokenId();

    await expect(token.ownerOf('0x0000000000000000000000000000000000000000')).
      to.be.revertedWith('ERC721: owner query for nonexistent token');
    expect(await token.ownerOf(currentTokenId)).to.be.equal(mintUser.address);
  });

  it('Should be after mint the token, increased tokenId', async () => {
    const [mintUser] = accounts;

    const tokenIdBeforeCreate = await token.getCurrentTokenId();

    const mintTx = await token.connect(mintUser).mint(tokenURI);
    await mintTx.wait();

    const tokenIdAfterCreate = await token.getCurrentTokenId();

    expect(tokenIdBeforeCreate).to.equal(0);
    expect(tokenIdAfterCreate).to.equal(tokenIdBeforeCreate.add(1));
  });

  it('After calling approved, it must be return getApprove', async () => {
    const [mintUser, approveUser] = accounts;

    const mintTx = await token.connect(mintUser).mint(tokenURI);
    await mintTx.wait();

    const tokenIdAfterCreate = await token.getCurrentTokenId();

    const approveTx = await token.approve(approveUser.address, tokenIdAfterCreate);
    await approveTx.wait();

    await expect(token.getApproved(10)).to.be.revertedWith('ERC721: approved query for nonexistent token');
    expect(await token.getApproved(tokenIdAfterCreate)).to.equal(approveUser.address);
  });

  it('After calling setApprovalAll, the value of isApprovedForAll must be changed', async () => {
    const [mintUser, approveUser] = accounts;

    const mintTx = await token.connect(mintUser).mint(tokenURI);
    await mintTx.wait();

    await expect(token.connect(mintUser).setApprovalForAll(mintUser.address, true)).to.be.revertedWith('ERC721: approve to caller');
    await expect(token.connect(mintUser).setApprovalForAll(approveUser.address, true)).to.emit(token, 'ApprovalForAll')
      .withArgs(mintUser.address, approveUser.address, true);

    expect(await token.isApprovedForAll(mintUser.address, approveUser.address)).to.equal(true);
  });
});