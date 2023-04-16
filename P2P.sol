// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract P2P{

    struct Prosumer{
        address id;
        uint256 balance;
        // +: want to sell
        // -: want to buy
        int energyStatus;
    }

    Prosumer[] public Prosumers;
    address[] public sellers;
    address[] public buyers;
    mapping(address => uint256) public address2Index;
    // rate between energy and token
    int  public rate=1000;
    int cashbackNum=100;
    

    function getRate() public view returns (int){
        return rate;
    }

    function addProsumer(address _id) public {
        address2Index[_id]=Prosumers.length;
        Prosumers.push(Prosumer(_id,0,0));
    }

    function checkIfRegistered(address requestAddress) view public returns (bool){
        for (uint256 i=0; i<Prosumers.length; ++i) 
        {
            if(Prosumers[i].id==requestAddress){
                return true;
            }
        }
        return false;
    }

    function topUp(address userAddress,uint256 amount) public payable {
        // uint256 amount = 10 * 10**18;
        uint256 index=address2Index[userAddress];
        Prosumers[index].balance+=amount;
    }

    function withDraw(address payable userAddress) public payable {
        uint256 index=address2Index[userAddress];
        require(Prosumers[index].energyStatus>=0,"You are currently requuesting for buying energy, cannot withdraw!");
        userAddress.transfer(Prosumers[index].balance);
        Prosumers[index].balance=0;
    }

    function addBuyer(address buyer) public {
        buyers.push(buyer);
    }

    function addSeller(address seller) public {
        sellers.push(seller);
    }

    // The trader can get cashback based on the order trading volume
    function incentive(address user, uint256 money)public {
        uint256 index=address2Index[user];
        Prosumers[index].balance+=money;
    }

    function sell(int energy,address userAddress) public {
        uint256 seller=address2Index[userAddress];
        require(Prosumers[seller].energyStatus>0 && Prosumers[seller].energyStatus>energy,"You don't have enough energy on your account, cannot sell!");
        incentive(userAddress, 2*uint256(energy*rate/cashbackNum));
        for (uint256 i=0; i<buyers.length; ++i)
        {   
            uint256 index=address2Index[buyers[i]];
            // if this buyer cannot fulfill our request
            if(-Prosumers[index].energyStatus<energy){
                energy+=Prosumers[index].energyStatus;
                uint256 amount=uint256((-Prosumers[index].energyStatus)*rate);
                Prosumers[seller].balance+=amount;
                Prosumers[index].balance-=amount;
                // Prosumers[seller].energyStatus=tmp;
                Prosumers[index].energyStatus=0;
            }else{
            // if this buyer can fulfill our request
                Prosumers[seller].balance+=uint256(energy*rate);
                Prosumers[index].balance-=uint256(energy*rate);
                Prosumers[index].energyStatus-=energy;
                Prosumers[seller].energyStatus=0;
                energy=0;
                break;
            }
        }
        Prosumers[seller].energyStatus+=energy;
        sellers=new address[](0);
        buyers=new address[](0);
        for (uint256 i=0; i<Prosumers.length;++i) 
        {
            if (Prosumers[i].energyStatus>0){
                sellers.push(Prosumers[i].id);
            }else if(Prosumers[i].energyStatus<0){
                buyers.push(Prosumers[i].id);
            }
        }
    }

    // the parameter is the amount of energy
    function buy(int energy,address userAddress) public {
        uint256 buyer=address2Index[userAddress];
        require(Prosumers[buyer].balance>=uint256(rate*energy),"You don't have enough money on your account, cannot sell!");
        incentive(userAddress, uint256(energy*rate/cashbackNum));
        Prosumers[buyer].energyStatus-=energy;
        for (uint256 i=0; i<sellers.length; ++i)
        {   
            uint256 index=address2Index[buyers[i]];
            // if this seller cannot fulfill our request
            if(Prosumers[index].energyStatus<energy){
                energy-=Prosumers[index].energyStatus;
                uint256 amount=uint256(Prosumers[index].energyStatus*rate);
                Prosumers[buyer].balance-=amount;
                Prosumers[index].balance+=amount;
                // Prosumers[seller].energyStatus=tmp;
                Prosumers[index].energyStatus=0;
            }else{
            // if this buyer can fulfill our request
                Prosumers[buyer].balance-=uint256(energy*rate);
                Prosumers[index].balance+=uint256(energy*rate);
                Prosumers[index].energyStatus+=energy;
                Prosumers[buyer].energyStatus=0;
                energy=0;
                break;
            }
        }
        // cannot be fulfilles, still need to buy more
        Prosumers[buyer].energyStatus-=energy;
        sellers=new address[](0);
        buyers=new address[](0);
        for (uint256 i=0; i<Prosumers.length;++i) 
        {
            if (Prosumers[i].energyStatus>0){
                sellers.push(Prosumers[i].id);
            }else if(Prosumers[i].energyStatus<0){
                buyers.push(Prosumers[i].id);
            }
        }
    }

    function checkEnergyStatus(address userAddress) public view returns(int){
        uint256 index= address2Index[userAddress];
        return Prosumers[index].energyStatus;
    }

    function checkBalance(address userAddress) public view returns(uint256){
        uint256 index= address2Index[userAddress];
        return Prosumers[index].balance;
    }

    function test() public {
        Prosumers[0].energyStatus=2;
        Prosumers[1].energyStatus=3;
        Prosumers[2].balance=10;
    }
}
