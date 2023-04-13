// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract P2P{

    struct Prosumer{
        address id;
        uint256 balance;
        int energyStatus;
    }

    Prosumer[] public Prosumers;
    mapping(address => uint256) public address2Index;
    // rate between energy and token
    int  public rate=1;

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

    function withDraw(address userAddress) public payable {
        uint256 index=address2Index[userAddress];
        require(Prosumers[index].energyStatus>=0,"You are currently requuesting for buying energy, cannot withdraw!");
        Prosumers[index].balance=0;
    }

    function sell(int energy,address userAddress) public {
        uint256 index=address2Index[userAddress];
        require(Prosumers[index].energyStatus>0 && Prosumers[index].energyStatus>energy,"You don't have enough energy on your account, cannot sell!");
        for (uint256 i=0; i<Prosumers.length; ++i) 
        {
            if (i==index || Prosumers[i].energyStatus>0){
                continue ;
            }
            int tmp=energy+Prosumers[i].energyStatus;
            if(tmp>0){
                uint256 amount=uint256((-Prosumers[i].energyStatus)*rate);
                Prosumers[index].balance+=amount;
                Prosumers[i].balance-=amount;
                Prosumers[index].energyStatus=tmp;
                Prosumers[i].energyStatus=0;
                energy=tmp;
            }else{
                Prosumers[index].balance+=uint256(energy*rate);
                Prosumers[i].balance-=uint256(energy*rate);
                Prosumers[i].energyStatus=tmp;
                Prosumers[index].energyStatus=0;
                energy=0;
            }
        }
        // after iterating every prosumer, still remains some energy
        Prosumers[index].energyStatus+=energy;
    }

    function buy(int energy,address userAddress) public {
        uint256 index=address2Index[userAddress];
        require(Prosumers[index].balance>uint256(rate*(-energy)),"You don't have enough money on your account, cannot sell!");
        for (uint256 i=0; i<Prosumers.length; ++i)
        {
            if (i==index || Prosumers[i].energyStatus<0){
                continue ;
            }
            int tmp=energy+Prosumers[i].energyStatus;
            if(tmp<0){
                uint256 amount=uint256(Prosumers[i].energyStatus*rate);
                Prosumers[index].balance-=amount;
                Prosumers[i].balance+=amount;
                Prosumers[index].energyStatus=tmp;
                Prosumers[i].energyStatus=0;
                energy=tmp;
            }else{
                // I need 3 (energy=-3), Prosumers[i] is 6
                Prosumers[index].balance+=uint256(energy*rate);
                Prosumers[i].balance-=uint256(energy*rate);
                Prosumers[i].energyStatus=tmp;
                Prosumers[index].energyStatus=0;
                energy=0;
            }
        }
        // after iterating every prosumer, still need some energy
        Prosumers[index].energyStatus+=energy;
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
