// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Citizens.sol";

contract XiSys {
    uint public totalGenratedTokens ; 

    address CEO ; 

    event ErrorMessage(string errorMessage);
    event SuccessMessage(string successMessage);

    constructor() {
        CEO = msg.sender ;
        totalGenratedTokens = 0 ;
    }

     struct Employee {
         address employeeWallet ;
         uint CNIC ; 
         bool status ; 
     }

     struct Bill  {
         address employeeAddress ; 
         uint tokenGenated ;
         uint billID ;
     }

    Bill[] public billHistory ;
    mapping(uint => Employee ) public Employees ;

     modifier isCEO(){
         require(msg.sender == CEO , "You are unauthorized");
         _;
     }

    //  modifier isEmployee(_id) {
    //      require(msg.sender == Employees[_id].walletAddress );
    //      _;
    //  }


      

     function addEmployee(address _wallet , uint _CNIC , uint _id) public isCEO {
         require (Employees[_id].status == false , "Already in service");
         Employees[_id].employeeWallet = _wallet ;
         Employees[_id].CNIC = _CNIC ; 
         Employees[_id].status = true;
     }
    
    function removeEmployee(uint _id , uint _CNIC) public isCEO {
        require(Employees[_id].status , "ALready removed");
        require(Employees[_id].CNIC == _CNIC , "Wrong CNIC");
        delete Employees[_id];
    }

    function addBalanceToPerson(address _contractAddress , address _citizenWallet, uint _CNIC , uint _amount , uint _employeeId , uint _billID) public {
        require(msg.sender == Employees[_employeeId].employeeWallet , "You are unauthorized");
        
        Citizens citizenObject ; 
        citizenObject = Citizens(_contractAddress) ;
        citizenObject.addBalance( _amount , _CNIC , _citizenWallet);

        Bill memory obj  ;
        obj.billID = _billID ;
        obj.employeeAddress = msg.sender;
        obj.tokenGenated = _amount ;
        billHistory.push(obj);
        totalGenratedTokens = totalGenratedTokens + _amount ;

        emit SuccessMessage("Added");
        

        // try  citizenObject.addBalance( _amount , _CNIC , _citizenWallet) {
        //     Bill memory obj  ;
        //     obj.billID = _billID ;
        //     obj.employeeAddress = msg.sender;
        //     obj.tokenGenated = _amount ;
        //     billHistory.push(obj);
        //     totalGenratedTokens = totalGenratedTokens + _amount ;
        // }catch   {
        //     emit ErrorMessage("Error ");
        // }
        
    }

    function rejectCititzenRequestSuper(uint _CNIC , address _citizenContractAddress , uint _employeeId ) public {
        require(msg.sender == Employees[_employeeId].employeeWallet , "Unotherized" );
        Citizens obj;
        obj = Citizens(_citizenContractAddress);
        obj.rejectCititzenRequest(_CNIC);
        

    }

    function approveCitizenResquestSuper(uint _CNIC , address _citizenContractAddress , address _citizenWallet , uint _employeeId) public {
        require(msg.sender == Employees[_employeeId].employeeWallet , "Unotherized" );
        Citizens obj ;
        obj = Citizens(_citizenContractAddress);
        obj.approveCitizen(_CNIC , _citizenWallet);
        emit SuccessMessage("Successfull");
    }

}