// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
contract NFTMarketplace is ERC1155Holder {
    IERC1155 Token;
    IERC20 paymentToken;
    uint256 orderId = 1;
    uint public constant platformFee = 10;
    address immutable owner;
    constructor(){
        owner = msg.sender;
    }
    
    struct nftsData {
        uint id;
        uint amount;
        uint price;
        uint paymentId;
        address nftAddress;
        address owner;
    }
    
    //mapping orderId to nftsData
    mapping(uint => nftsData) private setNFTsData;

    //mapping id to token Addresses
    mapping(uint => address) public paymentTokens;

    function setPaymentTokens(uint _paymentId,address _paymentToken) external{
        require(msg.sender == owner,"only Owner allowed");
        require(_paymentToken != address(0),"invalid TokenAddress");
        require(_paymentId > 0 && _paymentId < 5,"invalid Token Id");
        paymentTokens[_paymentId] = _paymentToken;

    }

    function listForSale(uint _id, uint _amount, uint _price , uint _paymentId,address _nftAddress) external {
        require(_price !=0 ,"invalid price");
        require(_id !=0,"invalid id");
        require(_amount !=0, "invalid  amount");
        require(_paymentId >0 && _paymentId <5,"invalid payment Id");
        Token =IERC1155(_nftAddress);
        require(address(Token) != address(0),"invalid NFT address");
        Token.safeTransferFrom(msg.sender,address(this),_id,_amount,"");
        setNFTsData[orderId]= nftsData(_id,_amount,_price,_paymentId,_nftAddress,msg.sender);
        orderId++;
    }

    function buyNFts(uint _orderId) external {
        address _owner =setNFTsData[_orderId].owner;
        Token=IERC1155(setNFTsData[_orderId].nftAddress);
        uint _id = setNFTsData[_orderId].id;
        uint totalNFTs = setNFTsData[_orderId].amount;
        uint priceOfNFT = setNFTsData[_orderId].price;
        uint _paymentId = setNFTsData[_orderId].paymentId;
        require(msg.sender != _owner, "owner can't buy");
        uint totalFee = (totalNFTs * priceOfNFT) /platformFee; 
        paymentToken = IERC20(paymentTokens[_paymentId]);
        uint payToOwner = (totalNFTs * priceOfNFT) - totalFee;
        paymentToken.transferFrom(msg.sender,address(this),totalFee);
        paymentToken.transferFrom(msg.sender,_owner,payToOwner);
        Token.safeTransferFrom(address(this),msg.sender,_id,totalNFTs,"");
        setNFTsData[_orderId].owner = msg.sender;
      
    }

    function getListedAmount(uint _orderId) external view returns(nftsData memory) {
        return setNFTsData[_orderId];
    }

}