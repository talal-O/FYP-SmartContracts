// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Block {
    
    address exectiveContract ;

    address landInspectorContract = 0xd9145CCE52D386f254917e481eB44e9943F39138;

    function changeAdminsContract(address _oldAddress ,  address _newcontractAddress ) public {
        require(msg.sender == exectiveContract , "You are unautherized");
        require(landInspectorContract == _oldAddress , "Wrong old Address");

        landInspectorContract = _newcontractAddress ;
    }

    function changeExective( address _exectiveContract ) public {
        require(msg.sender == exectiveContract , "You are unautherized");
        exectiveContract = _exectiveContract ;
    }
}
// ---------------------------------------------


contract Exective {
    address chairman ;

    constructor (){
        chairman = msg.sender ;
    }

    function changeAdminsContract(address _oldAddress , address _newcontractAddress , address _blockAddress) public {
        require(msg.sender == chairman , "You are unauthorized");
        Block blockObject ;
        blockObject = Block(_blockAddress);

        blockObject.changeAdminsContract(_oldAddress , _newcontractAddress);
    }

    function changeExectiveContract( address _newExectiveContract , address _blockAddress) public {
        require(msg.sender == chairman , "You are unauthorized");
        Block blockObject ;
        blockObject = Block(_blockAddress);

        blockObject.changeExective(_newExectiveContract);
    }


}