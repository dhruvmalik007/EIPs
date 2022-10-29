
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProofs.sol";


abstract contract KYCABST is IERC6595, MerkleProofs{
    using MerkleProofs for *;
    mapping(uint256 => IERC6595.Requirement[]) private _requiredMetadata;
    mapping(address => mapping(uint256 => bool)) private _SBTVerified;
    // this mapping stores the verifying addresses along with the hashes for the information details.
    mapping(address => bytes32[]) private proofInformation;
    // this is the public information supplied for the verification. 
    mapping(address => bytes32) private leafInformation; 
    bytes32 private root;
    address public admin;

    constructor() {
        admin = msg.sender;
    }
    function ifVerified(address verifying, uint256 SBTID) public override view returns (bool){

        return(_SBTVerified[verifying][SBTID]);
    }
    /// @notice defines the root of the hashes generated from the address of the user.

    /// @param newProof is the proof computed offchain from the leaf information of the leaf address.
    /// @return  true if the root of the address is set.
    /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)    
    function setRoot(bytes32 memory newProof) public view returns (bool) {
        require(msg.sender == admin, "only admin sets the root");
        root = newProof;
    }


    function setProofInformation(address verifier, bytes32[] proofDetails) public view returns(bool) {
        require(msg.sender == admin, "only admin sets the leaf info");
        proofInformation[verifier] = proofDetails;
        return(true);
    }

        function setLeafInformation(address verifier, bytes32 leafInfo) public view returns(bool) {
        require(msg.sender == admin, "only admin sets the leaf info");
        leafInformation[verifier] = leafInfo;
        return(true);
    }

    function standardRequirement(uint256 SBTID) public override view returns (Requirement[] memory){
        return(_requiredMetadata[SBTID]);
    }

    function changeStandardRequirement(uint256 SBTID, Requirement[] memory requirements) public override returns (bool){
        require(msg.sender == admin);
        _requiredMetadata[SBTID] = requirements;    
        emit standardChanged(SBTID, requirements);
        return(true);     
    }

    function certify(address certifying, uint256 SBTID) public override returns (bool){
        require(msg.sender == admin);
        // @dev: this is demo implementation checking whether the merkleRoot  
        require(proofInformation[certifying] && leafInformation[certifying], "proof hashes and leaf information of certifying address should be supplied");
        
        require(verify(proofInformation[certifying],root,leafInformation[certifying]), "not correct leaf information");
        _SBTVerified[certifying][SBTID] = true;
        emit certified(certifying, SBTID);
        return(true);     
    }

    function revoke(address certifying, uint256 SBTID) external override returns (bool){
        require(msg.sender == admin);
        _SBTVerified[certifying][SBTID] = false;
        emit revoked(certifying, SBTID);
        return(true);     
    }

}