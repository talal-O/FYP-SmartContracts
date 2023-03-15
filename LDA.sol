// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Block {
    bool isLdaApproved ;
    uint totalProperties = 0  ;

    struct Property {
    bool exists;
    address inspectorAddress;
    int sharesLeft;
    int sharesOwned;
    }

    mapping(uint => Property )  properties ;

// -------------------------------------------------------------------------------------
    function approve(address _blockAddress, uint _totalProperties ) public {
       
    }

    function increaseProperties(address _blockAddress , uint _addNumber) public {
       
    }
}
// ---------------------------------------------

contract LDA {
    address chairman ;

    constructor () {
        chairman = msg.sender;
    }
    struct officer {
        uint cnic; 
        bool status ; 
    }

    mapping(address => officer) admins ; 

    modifier isChairman(){
        require(msg.sender == chairman , "You are unauthorized");
        _;
    }

    modifier isAdmin(){
        require(admins[msg.sender].status , "You are unauthorized");
        _;
    }

    function addAdmin(address _address , uint _cnic ) public isChairman {
        admins[_address].cnic = _cnic;
        admins[_address].status = true;
    }

    function removeAdmin (address _address ) public isChairman{
        admins[_address].status = false ; 
    }

    function approveBlock(address _block , uint _totalProperties) public isAdmin {
        require(admins[msg.sender].status , "You are restricted");
        Block blockObject ;
        blockObject = Block(_block);
        
        blockObject.approve(_block , _totalProperties);
    }


    function increaseProperties (address _block , uint _number) public isAdmin{
        require(admins[msg.sender].status , "You are restricted");
        Block blockObject ;
        blockObject = Block(_block);

        blockObject.increaseProperties( _block, _number);
    }
    
}
