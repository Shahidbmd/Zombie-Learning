// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./IERC20.sol";
import "hardhat/console.sol";
contract TokenERC20 is ERC1155,Ownable {
    IERC20 PayToken = IERC20(0x07Cb88b1d6E06a5fd54Ae8d4A71713BF822f4389);
    constructor() ERC1155("") {}

    uint256 constant maxSupply = 5;

    //mapping ids to minting Fee
    mapping(uint => uint) public mintingFee;

    //mapping and id to number of NFTs minted
    mapping(uint => uint) public mintedNFTs;

    //mapping ids to nftCopies
    mapping(uint => uint) public nftCopies;

    function setMintingFee(uint _id, uint _mintingFee,uint _noOfCopies) external onlyOwner {
        require(_id != 0 && _id <= 5,"Id limit is 5");
        mintingFee[_id] = _mintingFee;
        nftCopies[_id] = _noOfCopies;
    }

    function mint(address account, uint256 id, uint256 amount)
        public
    {
        require(id != 0 && id <= maxSupply,"max limit is 5");
        require((amount + mintedNFTs[id]) <= nftCopies[id], "Crossed Mint Limit");
        uint tokensToPay = (mintingFee[id]) * amount;
        require(PayToken.balanceOf(msg.sender) >= tokensToPay,"unsufficient balance");
        require(PayToken.allowance(account,address(this)) >= tokensToPay ,"invalid minting Fee");
        PayToken.transferFrom(msg.sender, address(this),tokensToPay);
        mintedNFTs[id] += amount;
        _mint(account, id, amount,"");  
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public 
    { require(ids.length != 0 && ids.length < 5 ,"Max Supply is 5");
      
      uint[] memory Nfts = new uint[](ids.length);
      uint tokensToPay;
      for(uint i=0; i< Nfts.length; i++){
          require(((amounts[i] + mintedNFTs[ids[i]]) <= nftCopies[ids[i]]),"Crossed Mint Limit");
           uint amount = amounts[i] * mintingFee[ids[i]];
           tokensToPay += amount;
           mintedNFTs[ids[i]] += amounts[i];
      }
      require(PayToken.balanceOf(msg.sender) >= tokensToPay,"unsufficient balance");
      require(PayToken.allowance(msg.sender,address(this)) >= tokensToPay, "invalid minting Fee");
      PayToken.transferFrom(to, address(this),tokensToPay);
      _mintBatch(to, ids, amounts,"");
        
        
    }

}
