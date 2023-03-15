// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Parkview.sol";

contract Citizens{

    address public landInspectorContract = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
    address public XiSysContract =  0x1c91347f2A44538ce62453BEBd9Aa907C662b4bD ;
    address public nadraContract ;

    constructor () {
        landInspectorContract = msg.sender ;
        XiSysContract = msg.sender ;
    }

    struct CitizenStructure {
        address walletAddress;
        bool isAlive;
        uint propertyCoins;
        bool isApproved ;
        bool reTry;
    }
    mapping (uint => CitizenStructure) private citizensArray;

    // struct Successor {
    //     address successorWallet;
    //     uint tokens;
    //     uint OTPCode;
    //     address adminWallet;
    //     uint OTPAttempts;
    // }


    modifier isXiSys(){
        require(msg.sender == XiSysContract , "You are unauthorized");
        _;
    }

    function getCitizenIsAlive(uint _cnic) public view returns(bool isAlliveStatus){
        return citizensArray[_cnic].isAlive;
    }

    function getCitizenIsApproved(uint _cnic) public view returns(bool isApprovedStatus){
        return citizensArray[_cnic].isApproved;
    }

    function getCititzenWallet(uint _cnic) public view returns(address walletAddress){
        return citizensArray[_cnic].walletAddress;
    }


    function newCitizenRequest(uint _CNIC ) public {
        require(citizensArray[_CNIC].isApproved == false , "You already exist.");
        require(citizensArray[_CNIC].reTry == false , "You are in waiting List");
        citizensArray[_CNIC].reTry = true ;
        citizensArray[_CNIC].walletAddress = msg.sender ;
    }

    // Incomplete without XiSys Contract -----------------
    function approveCitizen(uint _CNIC , address _walletAddress) public isXiSys {
        require (citizensArray[_CNIC].reTry , "There is no request for that Person");
        require(citizensArray[_CNIC].isAlive == false , "Citizen alredy approved");
        require(citizensArray[_CNIC].isApproved == false , "Citizen alredy approved");
        require (citizensArray[_CNIC].walletAddress == _walletAddress , "Wrong wallet Address");
        citizensArray[_CNIC].isAlive = true;
        citizensArray[_CNIC].isApproved = true;
        citizensArray[_CNIC].propertyCoins = 0;
    }
    // Incomplete without XiSys Contract -----------------
    function rejectCititzenRequest(uint _CNIC) public isXiSys{
        require (citizensArray[_CNIC].reTry , "There is no request for that Person");
        require(citizensArray[_CNIC].isAlive == false , "Citizen is alredy approved");
        require(citizensArray[_CNIC].isApproved == false , "Citizen is alredy approved");
        delete citizensArray[_CNIC];
    }

    // Incomplete without Nadra Contract --------------------------------
    function declareDeathWithOutBalance(uint _CNIC ) public {
        require(msg.sender == nadraContract , "You are unauthorized");
        require(citizensArray[_CNIC].propertyCoins == 0  , "Citizen has some balance");
        citizensArray[_CNIC].isAlive = false ;
    }

    // Incomplete without Nadra Contract --------------------------------
    function declareDeathWithBalance(uint _CNIC , address _ownerWallet , uint _successorCnic , address _successorWallet) public {
        require(msg.sender == nadraContract , "You are unauthorized");
        require(citizensArray[_CNIC].propertyCoins > 0 , "Citizen balance is Zero");
        require(citizensArray[_successorCnic].isApproved , "This successor is not approved");
        require(citizensArray[_successorCnic].isAlive , "This successor is Died");
        require(citizensArray[_successorCnic].walletAddress == _successorWallet , "Successor Wallet wrong");
        require(citizensArray[_CNIC].walletAddress == _ownerWallet , "Owner wallet address is wrong");
        citizensArray[_successorCnic].propertyCoins = citizensArray[_successorCnic].propertyCoins + citizensArray[_CNIC].propertyCoins;
        citizensArray[_CNIC].propertyCoins = 0 ;
        citizensArray[_CNIC].isAlive = false ;
    }

    function addBalance(uint _amount , uint _CNIC ,address _userWallet ) public returns (bool)   {
        require(msg.sender == XiSysContract , "You are unauthorized");
        require(citizensArray[_CNIC].isApproved , "User is not approved");
        require(citizensArray[_CNIC].isAlive , "User Died");
        require(citizensArray[_CNIC].walletAddress == _userWallet , "Wallet address wrong ");
        citizensArray[_CNIC].propertyCoins = citizensArray[_CNIC].propertyCoins + _amount ;
        return true ;
    }

    function stakeCoinsInSociety(uint _cnic, uint _propertyTokensAmount , address _societyAddress) public {
        require(msg.sender == citizensArray[_cnic].walletAddress , "Unautherized Access" );
        require(citizensArray[_cnic].propertyCoins >= _propertyTokensAmount , "Enough Tokens");
        require(citizensArray[_cnic].isApproved , "User is not approved");
        require(citizensArray[_cnic].isAlive , "User Died");
        SocietyBlock obj;
        obj = SocietyBlock(_societyAddress) ;
        obj.stakePropertyCoins(_propertyTokensAmount , msg.sender );
        citizensArray[_cnic].propertyCoins -= _propertyTokensAmount;
    }
}
