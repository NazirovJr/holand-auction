// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract AucEngine {
    address public owner;
    uint constant DURATION = 2 days;
    uint constant FEE = 10;

    struct Auction {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stopped;
    }

    Auction[] public auctons;

    constructor() {
        owner = msg.sender;
    }

    event AuctionCreated(uint index, string itemName, uint startingPrice, uint duration);

    event AuctionEnded(uint index, uint finalPrice, address winner);

    function createAuction(uint _startingPrice, uint _discountRate, string calldata _item, uint _duration) external {
        uint duration = _duration == 0 ? DURATION : _duration;
        
        require(_startingPrice >= _discountRate * duration,"Incorrect strating Price");

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startingPrice:_startingPrice,
            finalPrice:_startingPrice,
            discountRate: _discountRate,
            startAt: block.timestamp,
            endsAt: block.timestamp + duration,
            item: _item,
            stopped:false
            });

            auctons.push(newAuction);
            emit AuctionCreated(auctons.length -1, _item, _startingPrice, _duration);
    }

    // function stop(uint index) {
    //     Auction storage cAuction = aucton[index];
    //     cAuction.stopped = true;
    // }

    function getPriceFor(uint index) public view returns(uint) {
        Auction storage cAuction = auctons[index];
        require(!cAuction.stopped,"stopped!");
        uint elapsed = block.timestamp - cAuction.startAt;
        uint discont = cAuction.discountRate * elapsed;
        return cAuction.startingPrice - discont;
    }

    function buy(uint index) external payable {
        Auction storage cAuction = auctons[index];
        require(!cAuction.stopped, "stopped!");
        require(block.timestamp < cAuction.endsAt, "ended!");
        uint cPrice = getPriceFor(index);
        require(msg.value >= cPrice, "Not enough funds!");
        cAuction.stopped = true;
        cAuction.finalPrice = msg.value;
        uint refund = msg.value - cPrice;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        cAuction.seller.transfer(cPrice - (cPrice * FEE) / 100);
        emit AuctionEnded(index, cPrice, msg.sender);
    }

}