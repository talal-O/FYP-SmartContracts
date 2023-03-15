// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract itemRemoval{
  uint[] public firstArray = [1,2,3,4,5];
  function removeItem(uint i) public{
    delete firstArray[i];
  }
  function getLength() public view returns(uint){
    return firstArray.length;
  }
  function remove(uint index) public{
    firstArray[index] = firstArray[firstArray.length - 1];
    firstArray.pop();
  }
}