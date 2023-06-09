// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./P2P.sol"; 

interface IP2P {
    function addProsumer(address _id) external ;
    function checkEnergyStatus(address userAddress) external  view returns(int);
    function checkBalance(address userAddress) external  view returns(uint256);
    function sell(int energy,address userAddress) external ; 
    function buy(int energy,address userAddress) external ; 
    function checkIfRegistered(address requestAddress) view external  returns (bool);
    function topUp(address userAddress,uint256 amount) external  payable;
    function getRate() external  view returns (int);
    function withDraw(address payable  userAddress) external  payable;
}


contract MainContract{
    address public owner;
    address P2PcontractAddress;

    function getP2P(address P2Paddress) public {
        P2PcontractAddress=P2Paddress;
    }

    function register() public forbidDuplicateRegistering{
        IP2P(P2PcontractAddress).addProsumer(msg.sender);
    }

    function checkEnergyStatus() public onlyRegistered view returns (int) {
        return IP2P(P2PcontractAddress).checkEnergyStatus(msg.sender);
    }

    function checkBalance() public onlyRegistered view returns (uint256) {
        return IP2P(P2PcontractAddress).checkBalance(msg.sender);
    }

    function energyRequest(int energy) public payable  onlyRegistered enoughMoney(energy) {
        if(energy>0){
            IP2P(P2PcontractAddress).sell(energy,msg.sender);
        }else if (energy<0){
            IP2P(P2PcontractAddress).buy(-energy,msg.sender);
        }
    }

    function topUp() public onlyRegistered payable{
        IP2P(P2PcontractAddress).topUp(msg.sender,msg.value);
    }

    function withdraw() public payable onlyRegistered {
        IP2P(P2PcontractAddress).withDraw(payable (msg.sender));
    }

    function testRegister() public {
        IP2P(P2PcontractAddress).addProsumer(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        IP2P(P2PcontractAddress).addProsumer(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        IP2P(P2PcontractAddress).addProsumer(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
    }

    modifier onlyRegistered(){
        require(IP2P(P2PcontractAddress).checkIfRegistered(msg.sender),"You are not registered yet!");
        _;
    }

    modifier forbidDuplicateRegistering(){
        require(!IP2P(P2PcontractAddress).checkIfRegistered(msg.sender),"You are already registered, do not register duplicate accounts!");
        _;
    }

    modifier enoughMoney(int energy){
        if (energy<0){
            require(checkBalance()>uint256(-energy*IP2P(P2PcontractAddress).getRate()),"You don't have enough balance to buy energy!");
        }
        _;
    }
}