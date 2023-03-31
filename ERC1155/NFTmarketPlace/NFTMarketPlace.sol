// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
contract NFTMarketplace is ERC1155Holder {
    uint256 orderId = 1;
    uint public constant platformFee = 10;
    address immutable owner;
    constructor(){
        owner = msg.sender;
    }

    //Events
    event NFTsStatus (uint indexed _orderId,uint indexed _id, IERC1155 indexed  _nftAddress, uint _amount, uint _price, uint _paymentId, address _owner, OrderStatus _orderStatus);
    event pamentMethods (uint indexed _paymentId, IERC20 indexed _paymentTokens);  

    //Order Enum
    enum OrderStatus {
     Open,
     Filled,
     Cancelled
    }
    
    //Listing Nfts data struct 
    struct nftsData {
        uint id;
        uint amount;
        uint price;
        uint paymentId;
        IERC1155 nftAddress;
        address owner;
    }
    
    //mapping orderId to nftsData
    mapping(uint => nftsData) private setNFTsData;

    //mapping id to token Addresses
    mapping(uint => IERC20) public paymentTokens;

    //mapping orderId to OrderStaus
    mapping(uint => OrderStatus) private NFT_Status;
     
    //set Payment methods
    function setPaymentTokens(uint _paymentId,IERC20 _paymentToken) external{
        require(msg.sender == owner,"only Owner allowed");
        require(address(_paymentToken) != address(0),"invalid TokenAddress");
        isValidId(_paymentId);
        paymentTokens[_paymentId] = _paymentToken;
        emit pamentMethods(_paymentId, _paymentToken);
    }

    //list ERC1155 NFTs
    function listForSale(uint _id, uint _amount, uint _price , uint _paymentId,IERC1155 _nftAddress) external {
        invalidValue(_id);
        invalidValue(_amount);
        invalidValue(_price);
        isValidId(_paymentId);
        require(address(_nftAddress) != address(0),"invalid NFT address");
        transferNFT(_nftAddress,msg.sender,address(this),_id,_amount);
        NFT_Status[orderId] = OrderStatus.Open;
        setNFTsData[orderId] = nftsData(_id,_amount,_price,_paymentId,_nftAddress,msg.sender);
        emit NFTsStatus(orderId,_id,_nftAddress, _amount, _price, _paymentId,msg.sender,NFT_Status[orderId]);
        orderId++;
    }
     
    //cancel listed NFTs
    function cancelListing(uint _orderId) external {
        nftsData memory NFTData = setNFTsData[_orderId];
        require(msg.sender == setNFTsData[_orderId].owner, "only Owner can cancel Listing");
        require(NFT_Status[orderId] == OrderStatus.Open,"NFT Not For Sale");
        NFT_Status[_orderId] = OrderStatus.Cancelled;
        transferNFT(NFTData.nftAddress,address(this),msg.sender,NFTData.id,NFTData.amount);
        delete setNFTsData[_orderId];
        emit NFTsStatus(_orderId,NFTData.id,NFTData.nftAddress, NFTData.amount, NFTData.price, NFTData.paymentId,NFTData.owner,NFT_Status[_orderId]);
    }
    
    //Buy Listed Nfts
    function buyNFts(uint _orderId) external {
        nftsData memory NFTData = setNFTsData[_orderId];
        require(NFT_Status[orderId] == OrderStatus.Open,"NFT Not For Sale");
        require(msg.sender != NFTData.owner, "owner can't buy");
        uint totalFee = (NFTData.amount * NFTData.price) /platformFee; 
        uint payToOwner = (NFTData.amount * NFTData.price) - totalFee;
        paymentGateway(paymentTokens[NFTData.paymentId], msg.sender, address(this),totalFee);
        paymentGateway(paymentTokens[NFTData.paymentId], msg.sender, NFTData.owner,payToOwner);
        transferNFT(NFTData.nftAddress,address(this), msg.sender,NFTData.id,NFTData.amount);
        NFT_Status[_orderId] = OrderStatus.Filled;
        delete setNFTsData[_orderId];
        emit NFTsStatus(_orderId,NFTData.id,NFTData.nftAddress, NFTData.amount, NFTData.price, NFTData.paymentId,msg.sender,NFT_Status[_orderId]);
    }
    
    //get NFT details from OrdereId
    function getNFTDetails(uint _orderId) external view returns (nftsData memory) {
        return setNFTsData[_orderId];
    }

    //get NFT status from orderId
    function nftsStatus(uint _orderId) external view returns (OrderStatus) {
        return NFT_Status[_orderId];
    }

    function paymentGateway(IERC20 wallet,address from , address to , uint fee) private {
        wallet.transferFrom(from,to,fee);
    }

    function isValidId(uint _paymentId) private pure {
        require(_paymentId > 0 && _paymentId < 5,"invalid Token Id");
    }

    function invalidValue(uint _value) private pure {
        require(_value !=0 ,"Invalid Price or Amount or Id");
    }

    function transferNFT(IERC1155 nftAddress,address from , address to, uint _id, uint _amount) private {
        nftAddress.safeTransferFrom(from,to,_id,_amount,"");
    }

}