// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Citizens.sol";

contract SocietyBlock {

    uint public societyEarnings = 0 ;

    bool public isLdaApproved ;
    uint public totalProperties = 0  ;
    uint public currentCountProperties = 0 ;

    address public LDA = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    address public exectiveContract = 0xd9145CCE52D386f254917e481eB44e9943F39138 ;
    address public landInspectorContract = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    address public CitizenContract = 0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99  ;


    struct Property {
    bool exists;
    // address inspectorAddress;
    uint sharesLeft;
    bool stay;
    // uint transferRequestsCount ;
    }

    constructor() {
        landInspectorContract = msg.sender ;
        LDA = msg.sender ;
        exectiveContract = msg.sender ;
    }

    modifier isLda() {
        require(msg.sender == LDA, "You are Unauthorized");
        _;
    }

    modifier isLandInspector() {
        require(msg.sender == landInspectorContract, "You are Unauthorized");
        _;
    }

    modifier isCitizenContract () {
        require(msg.sender == CitizenContract , "You are Unauthorized");
        _;
    }
    mapping(uint => Property ) public  properties ;
    mapping(address => uint ) public citizensStakedTokens ;

    event PrpertyTransactionRecord(uint indexed PropertyId ,  uint indexed BuyerCnic , uint indexed SellerCnic , uint SharesAmount , uint Prize , uint Time );
// -------------------------------------------------------------------------------------

    function stakePropertyCoins(uint _amount , address _citizenWallet) public isCitizenContract {
        citizensStakedTokens[_citizenWallet] += _amount ;
    }

    function approve(address _blockAddress , uint _checkPropertiesAmount) public isLda {
        require(currentCountProperties <= _checkPropertiesAmount , "Amount of total properties is grater");
        require(address(this) == _blockAddress , "Wrong contract");
        isLdaApproved = true ;
    }

    function increaseProperties(address _blockAddress, uint _addAmount) public isLda {
        require(_addAmount > 0 , "Amount must be grater then zero");
        require(address(this) == _blockAddress , "Wrong contract");
        totalProperties = totalProperties + _addAmount;
    }

    function changeAdminsContract(address _oldAddress ,  address _newcontractAddress) public {
        require(msg.sender == exectiveContract , "You are unautherized");
        require(landInspectorContract == _oldAddress , "Wrong old Address");

        landInspectorContract = _newcontractAddress ;
    }

    function changeExective( address _exectiveContract ) public {
        require(msg.sender == exectiveContract , "You are unautherized");
        exectiveContract = _exectiveContract ;
    }

event AddNewPropertyLog(uint indexed PropertyId , address indexed AddByInspector , uint Time);
function addNewProperty(uint _propertyId , address _inspector) external {
    require (msg.sender == landInspectorContract , "You are unauthorized");
    require(currentCountProperties < totalProperties , "Limit exceeded");
    require(properties[_propertyId].exists == false  ,"Property already exists");
        properties[_propertyId].sharesLeft = 100;
        properties[_propertyId].exists = true;
        currentCountProperties = currentCountProperties + 1;
        emit AddNewPropertyLog(_propertyId , _inspector , block.timestamp);
}
}

contract OwnerShip2 is SocietyBlock {

    constructor(address _citizenContractAddress){
        CitizenContract = _citizenContractAddress;
    }

    struct shareHoldersStruct {
        address shareholdersAddress ;
        uint shares ;
        uint time;
    }

    struct PropertyShares {
        uint256 persentageSum;
        uint totalShareholders ;
        uint[] shareholdersCnicArray;
        mapping(uint=> shareHoldersStruct ) shareholders ;
    }

    mapping(uint => PropertyShares) public shareRecords;

    event SellNewPropertyLog(uint indexed PropertyId , uint BuyerCnic ,  uint Shares , uint AmountOfPropertyCoins , address indexed InspectorAddress , uint Time);

    function sellNewProperty(uint _propertyId , uint _cnic , uint _sharesPercentage , uint _propertyTokensAmount , address _inspectorAddress) public payable isLandInspector {
        require(properties[_propertyId].stay == false , "This property is restricted" );
        require(
            _sharesPercentage > 0 &&
                _sharesPercentage <= 100 &&
                (shareRecords[_propertyId].persentageSum + _sharesPercentage) <= 100,
            "Percentages are not valid"
        );
        require(isLdaApproved == true , "Not approved by LDA");
        require(properties[_propertyId].exists , "Property not exist is Society");
        Citizens obj ;
        obj = Citizens(CitizenContract);
        require(obj.getCitizenIsAlive(_cnic) , "Citizen not valid");
        require(obj.getCitizenIsApproved(_cnic) , "Citizen is not apprved");
        address _citizenWallet = obj.getCititzenWallet(_cnic);
        require(citizensStakedTokens[_citizenWallet] >= _propertyTokensAmount , "Enough Tokens!");

        if(shareRecords[_propertyId].shareholders[_cnic].shares == 0){
            shareRecords[_propertyId].totalShareholders++ ;
            shareRecords[_propertyId].shareholdersCnicArray.push(_cnic);
        }
        shareRecords[_propertyId].shareholders[_cnic].shareholdersAddress = _citizenWallet ;
        shareRecords[_propertyId].shareholders[_cnic].shares += _sharesPercentage ;
        shareRecords[_propertyId].shareholders[_cnic].time = block.timestamp;
        // shareRecords[_propertyId].persentageSum = shareRecords[_propertyId].persentageSum + sharesAmount ;
        shareRecords[_propertyId].persentageSum += _sharesPercentage ;
        // citizensStakedTokens[_citizenWallet] = citizensStakedTokens[_citizenWallet] - propertyTokensAmount ;
        citizensStakedTokens[_citizenWallet] -= _propertyTokensAmount ;
        societyEarnings += _propertyTokensAmount ;
        // properties[_propertyId].inspectorAddress = _inspectorAddress;
        properties[_propertyId].sharesLeft -= _sharesPercentage ;

        emit SellNewPropertyLog(_propertyId , _cnic , _sharesPercentage , _propertyTokensAmount , _inspectorAddress , block.timestamp);

    }

    //-----------------------------

    struct RequestTransferDetails {
        uint ownerCnic ;
        uint buyerCnic ;
        uint totalPrice ;
        uint transferSharesAmount ;
        address buyerWallet ;
        bool buyerSignature ;
    }

    struct RequestStruct {
        uint requestsCount ;
        mapping(uint => RequestTransferDetails ) requestDetailsArray ;
    }
        mapping(uint => RequestStruct) private transferRequests ;
    //-----------------------------

    function signatureForBuyer(uint _propertyId , uint _ownerCnic , uint _sharesAmount , uint _requestNumber) public {
        require(transferRequests[_propertyId].requestDetailsArray[_requestNumber].buyerWallet == msg.sender , "This request is not belongs to you");
        require(transferRequests[_propertyId].requestDetailsArray[_requestNumber].transferSharesAmount == _sharesAmount , "Wrong Shares Amount");
        require(transferRequests[_propertyId].requestDetailsArray[_requestNumber].ownerCnic == _ownerCnic , "Owner Cnic wrong " );

        transferRequests[_propertyId].requestDetailsArray[_requestNumber].buyerSignature = true ;
    }



    event TransactionRequestLogs(uint indexed PropertyId , uint indexed OwnerCnic , uint indexed BuyerCnic , uint Shares, uint PrizeOFOneShare , uint RequestNumber, uint Time  );

    function transferOwnerShipRequest(uint _OwnerCnic , uint _propertyId , uint _transferSharesAmount , uint _priceOfOneShare , uint _buyerCnic ) public {
        // Time limit for 5 mintues
        require(shareRecords[_propertyId].shareholders[_OwnerCnic].time + 300 < block.timestamp, "Time limit not full fill");
        require(properties[_propertyId].stay == false , "This property is restricted by highcourt" );
        Citizens obj;
        obj = Citizens(CitizenContract);
        require(obj.getCitizenIsAlive(_OwnerCnic) , "Owner is not allowed and restricted");
        require(obj.getCitizenIsApproved(_OwnerCnic) , "Owner must be approved");
        require(shareRecords[_propertyId].shareholders[_OwnerCnic].shareholdersAddress == msg.sender , "You are Unauthorized");
        require(shareRecords[_propertyId].shareholders[_OwnerCnic].shares >=  _transferSharesAmount , "Enough Shares");

        require(obj.getCitizenIsApproved(_buyerCnic) , "Buyer must be approved");
        require(obj.getCitizenIsAlive(_buyerCnic) , "Buyer must be alive");

        uint _totalPrice = _priceOfOneShare * _transferSharesAmount ;
        require( citizensStakedTokens[obj.getCititzenWallet(_buyerCnic)] >= _totalPrice , "Buyer has enough cois!" );

        // properties[_propertyId].transferRequestsCount++;
        uint blockTime = block.timestamp;
        // transferRequests[_propertyId].requestsNumbers.push(properties[_propertyId].transferRequestsCount);
        // if(transferRequests[_propertyId].requestDetailsArray[blockTime].ownerCnic != 0 ){
        //     revert("Transaction revert, Please Try Again");
        // }
        // Assync

        require(transferRequests[_propertyId].requestDetailsArray[blockTime].ownerCnic == 0  , "Transaction revert, Please Try Again" );
        transferRequests[_propertyId].requestsCount++ ;
        transferRequests[_propertyId].requestDetailsArray[blockTime].ownerCnic = _OwnerCnic;
        transferRequests[_propertyId].requestDetailsArray[blockTime].buyerCnic = _buyerCnic;
        transferRequests[_propertyId].requestDetailsArray[blockTime].totalPrice = _totalPrice;
        transferRequests[_propertyId].requestDetailsArray[blockTime].transferSharesAmount = _transferSharesAmount;
        transferRequests[_propertyId].requestDetailsArray[blockTime].buyerWallet = obj.getCititzenWallet(_buyerCnic);

        emit TransactionRequestLogs( _propertyId , _OwnerCnic , _buyerCnic , _transferSharesAmount , _totalPrice , blockTime, block.timestamp );
    }

    // struct TransactionRecord {
    //     uint256 from ;
    //     uint256 to ;
    //     // uint256 pricePropertyCoins ;
    //     uint256 shares ;
    //     uint256 timestamp ;
    //     address landinspectorWallet; // Only in the senario of Society

    // }

    // struct TransactionRecordArrayStruct {
    //     uint arrayCount ;
    //     TransactionRecord[] transactionDetailsArray;
    // }

    // mapping (uint => TransactionRecordArrayStruct ) public TransactionRecordArray ;

    // SQL Database main record krny ky liya
    event IndexOfRecordedTransaction(uint IndexIs , uint PropertyID , uint256 From , uint256 To , uint256 Shares );

    // function saveTransactionRecord(uint _propertyId , uint256 _from , uint256 _to , uint256 _shares , address _inspectorWallet ) private {
    //     TransactionRecord memory obj ;
    //     obj = TransactionRecord(_from , _to , _shares , block.timestamp , _inspectorWallet );
    //     if(TransactionRecordArray[_propertyId].arrayCount < 50){
    //         TransactionRecordArray[_propertyId].transactionDetailsArray[TransactionRecordArray[_propertyId].arrayCount] = obj ;
    //         TransactionRecordArray[_propertyId].arrayCount++ ;
    //         emit IndexOfRecordedTransaction(TransactionRecordArray[_propertyId].arrayCount - 1 , _propertyId , _from , _to , _shares  );

    //     }else {
    //         TransactionRecordArray[_propertyId].arrayCount = 0 ;
    //         TransactionRecordArray[_propertyId].transactionDetailsArray[TransactionRecordArray[_propertyId].arrayCount] = obj ;
    //         TransactionRecordArray[_propertyId].arrayCount++ ;
    //         emit IndexOfRecordedTransaction(TransactionRecordArray[_propertyId].arrayCount - 1 , _propertyId , _from , _to , _shares  );
    //     }

    // }
    event ConfirmedTransactionRequestsLogs(uint indexed PropertyId , uint indexed RequestNumber , uint OwnerCnic , uint BuyerCnic , address indexed LandInspectorWallet );

    event TransactionRecordLogs(uint indexed PropertyID , uint indexed SellerCnic , uint256 indexed BuyerCnic , uint256 Shares , uint prize, uint Time);

    function approveTransferRequest(uint _propertyId , uint _requestNumber , uint _ownerCnic , uint _buyerCnic , address _landinspectorWallet) public isLandInspector {
        require( _ownerCnic == transferRequests[_propertyId].requestDetailsArray[_requestNumber].ownerCnic , "Owner Cnic Worng");
        require( _buyerCnic == transferRequests[_propertyId].requestDetailsArray[_requestNumber].buyerCnic , "Buyer Cnic Worng");

        uint _shareAmount = transferRequests[_propertyId].requestDetailsArray[_requestNumber].transferSharesAmount ;
        uint _totalPrice = transferRequests[_propertyId].requestDetailsArray[_requestNumber].totalPrice ;
        require(shareRecords[_propertyId].shareholders[_ownerCnic].shares >=  _shareAmount , "Enough Shares");

        Citizens obj ;
        obj = Citizens(CitizenContract);

        address _buyerWallet = obj.getCititzenWallet(_buyerCnic);
        address _ownerWallet = obj.getCititzenWallet(_ownerCnic);

        require(citizensStakedTokens[_buyerWallet] >= _totalPrice , "Buyer has enough cois!" );

        if(shareRecords[_propertyId].shareholders[_buyerCnic].shares == 0){
            shareRecords[_propertyId].totalShareholders++ ;
            shareRecords[_propertyId].shareholdersCnicArray.push(_buyerCnic);
        }

        shareRecords[_propertyId].shareholders[_ownerCnic].shares -= _shareAmount;
        shareRecords[_propertyId].shareholders[_buyerCnic].shares += _shareAmount;
        shareRecords[_propertyId].shareholders[_buyerCnic].shareholdersAddress = _buyerWallet ;
        shareRecords[_propertyId].shareholders[_buyerCnic].time = block.timestamp;

        citizensStakedTokens[_buyerWallet] -= _totalPrice ;
        citizensStakedTokens[_ownerWallet] += _totalPrice;


        // Now Remove Extra Share Holders with zero shares
        if (shareRecords[_propertyId].shareholders[_ownerCnic].shares == 0  ){
            delete shareRecords[_propertyId].shareholders[_ownerCnic] ;
            shareRecords[_propertyId].totalShareholders-- ;

            for(uint i ; i < shareRecords[_propertyId].shareholdersCnicArray.length ; i++ ){
            if (shareRecords[_propertyId].shareholdersCnicArray[i] == _ownerCnic ) {
                // delete shareRecords[_propertyId].shareholdersCnicArray[i];
                shareRecords[_propertyId].shareholdersCnicArray[i] = shareRecords[_propertyId].shareholdersCnicArray[shareRecords[_propertyId].shareholdersCnicArray.length - 1];
                // Check and Dry Run this Below Statment
                shareRecords[_propertyId].shareholdersCnicArray.pop();
                break;
            }
        }
        }
        transferRequests[_propertyId].requestsCount-- ;
        if(transferRequests[_propertyId].requestsCount == 0 ){
            delete transferRequests[_propertyId];
            // delete properties[_propertyId].transferRequestsCount;
        }

        delete transferRequests[_propertyId].requestDetailsArray[_requestNumber] ;

        // saveTransactionRecord(_propertyId , _ownerCnic , _buyerCnic , _shareAmount , _landinspectorWallet);

    emit TransactionRecordLogs(_propertyId , _ownerCnic , _buyerCnic , _shareAmount, _totalPrice, block.timestamp );

    emit ConfirmedTransactionRequestsLogs(_propertyId, _requestNumber , _ownerCnic , _buyerCnic , _landinspectorWallet);

    }


    function getDetailsOfShares(uint _propertyId , uint _cnic ) public view returns(uint persentageSum , uint totalShareHolders , uint[] memory shareHoldersArray , uint sharesOfThisPerson) {

        return (
            shareRecords[_propertyId].persentageSum ,
            shareRecords[_propertyId].totalShareholders ,
            shareRecords[_propertyId].shareholdersCnicArray,
            shareRecords[_propertyId].shareholders[_cnic].shares
        );
    }

    struct ReverseCaseDetails{
        uint cutFrom;
        uint addTo ;
        uint sharesAmount ;
        bool signatureForGovermentAuthority ;
        uint OTP;
    }

    struct Cases {
        // uint[] caseNumbersArray ;
        mapping (uint => ReverseCaseDetails ) detailsOfCasesArray ;
    }

    mapping (uint => Cases ) private reverseCasesArray;

    event ReverseCases(uint indexed PropertyId , uint indexed CaseNumber , uint CutFromCNIC , uint indexed AddToCNIC , uint AmountOfShares , uint Time );

    // isHighCourt require Function required
    function generateReverseCase(uint _propertyId , uint _caseNumber , uint _cutFrom , uint _addTo , uint _amountOfShares ,uint OTPCode  ) public {
        require(shareRecords[_propertyId].shareholders[_cutFrom].shares >= _amountOfShares , "Enough shares" );
        Citizens obj;
        obj = Citizens(CitizenContract);
        require(obj.getCitizenIsAlive(_addTo) , "Second person is not allowed and restricted");
        require(obj.getCitizenIsApproved(_addTo) , "Second person must be approved");

        // Make this Owner to Stay  Function

        ReverseCaseDetails memory reverseObj ;
        reverseObj = ReverseCaseDetails(_cutFrom , _addTo , _amountOfShares , false , OTPCode);

        // reverseCasesArray[_propertyId].caseNumbersArray.push(_caseNumber);

        reverseCasesArray[_propertyId].detailsOfCasesArray[_caseNumber] = reverseObj;

    emit ReverseCases(_propertyId , _caseNumber , _cutFrom , _addTo , _amountOfShares , block.timestamp);


    }

    // is Lda only
    function singnatureToReverseCase(uint _propertyId , uint _caseNumber , uint _verficationOTPCode , uint _newOTPCode ) public isLda {
        require(reverseCasesArray[_propertyId].detailsOfCasesArray[_caseNumber].OTP ==  _verficationOTPCode , "Invalid Information");

        reverseCasesArray[_propertyId].detailsOfCasesArray[_caseNumber].signatureForGovermentAuthority = true ;
        reverseCasesArray[_propertyId].detailsOfCasesArray[_caseNumber].OTP  = _newOTPCode ;


    }

    event ConfirmedReverseCaseLogs(uint indexed PropertyId , uint indexed CaseNumber , uint CutFromCnic , uint AddToCnic , uint Shares , address LandInspectorWallet , uint Time );

    // For LandInspector
    function executeReverseCase(uint _propertyId , uint _caseNumber , uint _verficationOTPCode , address _landInspectorWallet ) public  isLandInspector {
        require(reverseCasesArray[_propertyId].detailsOfCasesArray[_caseNumber].OTP ==  _verficationOTPCode , "Invalid Information");
        uint _cutFrom = reverseCasesArray[_propertyId].detailsOfCasesArray[_caseNumber].cutFrom ;
        uint _addTo = reverseCasesArray[_propertyId].detailsOfCasesArray[_caseNumber].addTo ;
        uint _amountOfShares = reverseCasesArray[_propertyId].detailsOfCasesArray[_caseNumber].sharesAmount ;

        Citizens obj ;
        obj = Citizens(CitizenContract);

        address _secondPersonWallet = obj.getCititzenWallet(_addTo);

        if(shareRecords[_propertyId].shareholders[_addTo].shares == 0){
            shareRecords[_propertyId].totalShareholders++ ;
            shareRecords[_propertyId].shareholdersCnicArray.push(_addTo);
        }

        shareRecords[_propertyId].shareholders[_cutFrom].shares -= _amountOfShares;
        shareRecords[_propertyId].shareholders[_addTo].shares += _amountOfShares;
        shareRecords[_propertyId].shareholders[_addTo].shareholdersAddress = _secondPersonWallet ;
        shareRecords[_propertyId].shareholders[_addTo].time = block.timestamp;
        // Now Remove Extra Share Holders with zero shares
        if (shareRecords[_propertyId].shareholders[_cutFrom].shares == 0  ){
            delete shareRecords[_propertyId].shareholders[_cutFrom] ;
            shareRecords[_propertyId].totalShareholders-- ;

            for(uint i ; i < shareRecords[_propertyId].shareholdersCnicArray.length ; i++ ){
            if (shareRecords[_propertyId].shareholdersCnicArray[i] == _cutFrom ) {
                // delete shareRecords[_propertyId].shareholdersCnicArray[i];
                shareRecords[_propertyId].shareholdersCnicArray[i] = shareRecords[_propertyId].shareholdersCnicArray[shareRecords[_propertyId].shareholdersCnicArray.length - 1];
                // Check and Dry Run this Below Statment
                shareRecords[_propertyId].shareholdersCnicArray.pop();
                break;
            }
        }
        }

    emit ConfirmedReverseCaseLogs(_propertyId , _caseNumber , _cutFrom , _addTo , _amountOfShares, _landInspectorWallet , block.timestamp );

    }

    // isHighCourt require Function required
    // function highCourtVoteForReverse(uint _propertyId , uint _indexNumber , uint _from , uint _to , uint _shares ) public {
    //     require( TransactionRecordArray[_propertyId].transactionDetailsArray[_indexNumber].from == _from , "Previous Owner is not matched");
    //     require( TransactionRecordArray[_propertyId].transactionDetailsArray[_indexNumber].to == _to , "Previous Buyer is not matched");
    //     require( TransactionRecordArray[_propertyId].transactionDetailsArray[_indexNumber].shares == _shares  , "Previous shares not matched");
    //     TransactionRecordArray[_propertyId].transactionDetailsArray[_indexNumber].votesForReverse++ ;
    // }
    // IsLDA require Function required
    // function GovermentAuthorityVoteForReverse(uint _propertyId , uint _indexNumber , uint _from , uint _to , uint _shares ) public {
    //     require( TransactionRecordArray[_propertyId].transactionDetailsArray[_indexNumber].from == _from , "Previous Owner is not matched");
    //     require( TransactionRecordArray[_propertyId].transactionDetailsArray[_indexNumber].to == _to , "Previous Buyer is not matched");
    //     require( TransactionRecordArray[_propertyId].transactionDetailsArray[_indexNumber].shares == _shares  , "Previous shares not matched");
    //     TransactionRecordArray[_propertyId].transactionDetailsArray[_indexNumber].votesForReverse++ ;
    // }


}
