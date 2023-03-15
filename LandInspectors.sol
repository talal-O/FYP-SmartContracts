// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Parkview.sol";

contract LandInspectors {

    address soceityExectivesContract;
    mapping(address => inspectorsInfo )  admins;

    constructor (){
        soceityExectivesContract = msg.sender ; 
    }

    struct inspectorsInfo {
        uint cnic ;
        bool status ;
    }

    function addLandInspector(address _inspector) public {
        require(msg.sender == soceityExectivesContract , "You are unauthorized");
        admins[_inspector].status = true ;
    }

    function removeLandInspector(address _inspector) public {
        require(msg.sender == soceityExectivesContract , "You are unauthorized");
        admins[_inspector].status = false ;
    }

    // function changeAreaOfLandInspector(address _inspector , address _areaContract) public {
    //     require(msg.sender == soceityExectivesContract , "You are unauthorized");
    //     admins[_inspector].areaContractAddress = _areaContract ;
    // }

    function mintProperty(address blockAddress, uint _propertyId ) external  {
         
        require(admins[msg.sender].status == true , "You are unauthorized");
        Block blockContract ;
        blockContract = Block(blockAddress);

        blockContract.addNewProperty(_propertyId , msg.sender);

    }

}