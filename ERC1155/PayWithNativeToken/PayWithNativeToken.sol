// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PayWithNativeToken is ERC1155,Ownable {
    constructor() ERC1155("") {}

    uint256 constant maxSupply = 5;

    //mapping ids to minting Fee
    mapping(uint => uint) private mintingFee;

    //mapping and id to number of NFTs minted
    mapping(uint => uint) private mintedNFTs;

    //mapping ids to nftCopies
    mapping(uint => uint) private nftCopies;

      function mintingFeeIs(uint _id) external view returns(uint) {
        return mintingFee[_id];
    }

    function mintedNftsAre(uint _id) external view returns(uint) {
        return mintedNFTs[_id];
    }
    
    function noOfCopies(uint _id) external view returns(uint) {
        return nftCopies[_id];
    }

    function setMintingFee(uint _id, uint _fee,uint _noOfCopies) external onlyOwner {
        require(_id != 0 && _id <= maxSupply,"Id limit is 5");
        mintingFee[_id] = _fee;
        nftCopies[_id] = _noOfCopies;
    }

    function mint(address account, uint256 id, uint256 amount)
        external payable
    {
        require(id != 0 && id <= maxSupply,"max limit is 5");
        require((amount + mintedNFTs[id]) <= nftCopies[id], "Crossed Mint Limit");
        require(msg.value == ((mintingFee[id]) * amount),"invalid minting Fee");
        mintedNFTs[id] += amount;
        _mint(account, id, amount, "");  
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        external payable
    { require(ids.length != 0 && ids.length < maxSupply ,"Max Supply is 5");
      
      uint[] memory Nfts = new uint[](ids.length);
      uint feeIs;
      for(uint i=0; i< Nfts.length; i++){
          require(ids[i] <5 &&  ids[i] !=0, "Invalid Ids");
          require(((amounts[i] + mintedNFTs[ids[i]]) <= nftCopies[ids[i]]),"Crossed Mint Limit");
           uint amount = amounts[i] * mintingFee[ids[i]];
           feeIs += amount;
           uint noOfNfts = amounts[i];
           mintedNFTs[ids[i]] += noOfNfts;
      }
      require(msg.value == feeIs, "invalid minting Fee");
      _mintBatch(to, ids, amounts, "");
        
        
    }
}
