// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnerShip {

    struct PropertyShares {
        uint256 persentageSum;
        uint totalShareholders ;
        mapping(uint=> address ) shareholders ;
        mapping(address=> uint256 ) shares ;
    }

    mapping(uint => PropertyShares) internal shareRecords;


    function newProperty


}