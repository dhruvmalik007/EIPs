---
eip: 5185
title: issuer and verifier of KYC certificates. 
description: Interface for assigning/validating identities using Zero Knowledge Proofs
author: Yu Liu (@yuliu-debond), Dhruv Malik (@dhruvmalik007)
discussions-to: https://ethereum-magicians.org/t/eip-5185-kyc-certification-issuer-and-verifier-standard/11513
status: Draft
type: Standards Track
category : ERC
created: 2022-10-18
requires: 721, 1155, 5114, 3643
---


## Abstract

- This EIP Provides defined interface for KYC verification with abstract onchain conditions.

- This EIP defines the necessary interface for orchestrator to assign identity certificates (as Soulbound tokens) to the wallets, which can be verified by ZK schemes.

## Motivation

Onchain verification is becoming indispensable across DeFI as well as other web3 protocols (DAO, governance) as its needed not only by the government for regulatory purposes, but also by different DeFI protocols to whitelist the users which fullfill the certain criterias.

This created the necessity of building onchain verification of the addresses for token transfers (like stablecoin providers check for the blacklisted entities for the destination address, limited utility tokens for a DAO community , etc). Along with the concern that current whitelisting process of the proposals are based on the addition of the whitelisted addresses (via onchain/offchain signatures) and thus its not trustless for truly decentralised protocols. 


Also Current standards in the space, like [eip-3643](./eip-3643.md) are insufficient to handle the complex usecases where: 

    - The validation logic needs to be more complex than verification of the user identity wrt the blacklisted address that is defined offchain, and is very gas inefficient. 

    - Also privacy enhanced/anonymous verification is important need by the crypto users in order to insure censorship/trustless networks. ZK based verification schemes are currently the only way to validate the assertion of the identity by the user, while keeping certain aspects of the providers identity completely private.

thus in order to address the above major challenges: there is need of standard that defines the interface of contract which can issue an immutable identity for the identifier (except by the user) along with verifying the identity of the user based on the ownership of the given identity token.

## Specification:

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

**Definition**

- SBT: Soulbound tokens, these are non-fungible and non transferrable tokens that is used for defining the identity of the users. they are defined by standard [eip-5192](./eip-5192.md).

- SBT Certificates: SBT that represent the ownerships of ID signatures corresponding to the requirements defined in `function standardRequirement()`.

- KYC standard: Know your customer standard are the set of minimum viable conditions that financial services providers (banks, investment providers and other intermediate financial intermediateries) have to satisfy in order to access the services. this in web3 consideration concerns not about the details about the user itself, but about its status (onchain usage, total balance by the anon wallet, etc) that can be used for whitelisting.
**diagram**
[diagram](../assets/eip-zkID/architecture-diagram.png)
example workflow using preimage verification: 
- here the KYC contract is an oracle that assigns the user identity with the SBT certificate.
- During issuance stage, the process to generate the offchain compute of the merkle root from the various primairly details are calculated and then assigned onchain to the given wallet address with the identity (as SBT type of smart contract certificate).
- on the other hand, the verifier is shared part of the nodes and the merkle root, in order to verify the merkle leaf information.
- thus during the verification stage, the verifier will be provided with the preimage of the proofs along with the public information. then via offchain, the admin will compute the merkleroot of the given information and then assign the SBT certificate to the user
- once having the certificate, the functions that allow the SBTID as assigned by the given user, they will be whitelisted to do the function calls.
**Functions**

```solidity
pragma solidity ^0.8.0;
    // getter function 
    /// @notice getter function to validate if the address `verifying` is the holder of the SBT defined by the tokenId `SBTID`
    /// @dev it MUST be defining the logic corresponding to all the current possible requirements definition.
    /// @param verifying is the EOA address that wants to validate the SBT issued to it by the KYC. 
    /// @param SBTID is the Id of the SBT that user is the claimer.
    /// @return true if the assertion is valid, else false
    /**
    example ifVerified(0xfoo, 1) --> true will mean that 0xfoo is the holder of the SBF identity token defined by tokenId of the given collection. 
    */
    function ifVerified(address verifying, uint256 SBFID) external view returns (bool);

    /// @notice getter function to fetch the onchain identification logic for the given identity holder.
    /// @dev it MUST not be defined for address(0). 
    /// @param SBTID is the Id of the SBT that user is the claimer.
    /// @return the struct array of all the descriptions of condition metadata that is defined by the administrator.
    /**
    ex: standardRequirement(1) --> {
    { "title":"DepositRequirement",
        "type": "number",
        "description": "defines the minimum deposit in USDC for the investor along with the credit score",
        },
       "logic": "and",
    "values":{"30000", "5"}
}
Defines the condition encoded for the identity index 1, defining the identity condition that holder must have 30000 USDC along with credit score of atleast 5.
    */
    function standardRequirement(uint256 SBFID) external view returns (Requirement[] memory);

    // setter functions
    /// @notice function for setting the requirement logic (defined by Requirements metadata) details for the given identity token defined by SBTID.
    /// @dev it should only be called by the admin address.
    /// @param SBFID is the Id of the SBT based identity certificate for which admin wants to define the Requirements.
    /// @param `requirements` is the struct array of all the descriptions of condition metadata that is defined by the administrator. check metadata section for more information.
/**
example: changeStandardRequirement(1, { "title":"DepositRequirement",
    "type": "number",
    "description": "defines the minimum deposit in USDC for the investor along with the credit score",
    },
    "logic": "and",
    "values":{"30000", "5"}
}); 
will correspond to the the functionality that admin needs to adjust the standard requirement for the identification SBT with tokenId = 1, based on the conditions described in the Requirements array struct details.
**/
    function changeStandardRequirement(uint256 SBFID, Requirement[] memory requirements) external returns (bool);
    
    /// @notice function which uses the ZKProof protocol in order to validate the identity based on the given 
    /// @dev it should only be called by the admin address.
    /// @param SBFID is the Id of the SBT based identity certificate for which admin wants to define the Requirements.
    /// @param certifying is the address that needs to be proven as the owner of the SBT defined by the tokenID.
    /// @param `requirements` is the struct array of all the descriptions of condition metadata that is defined by the administrator. check metadata section for more information.
    function certify(address certifying, uint256 SBFID) external returns (bool);

    /// @notice function which uses the ZKProof protocol in order to validate the identity based on the given 
    /// @dev it should only be called by the admin address.
    /// @param SBFID is the Id of the SBT based identity certificate for which admin wants to define the Requirements.
    /// @param certifying is the address that needs to be proven as the owner of the SBT defined by the tokenID.
    /// @param `requirements` is the struct array of all the descriptions of condition metadata that is defined by the administrator. check metadata section for more information.
    // eg: revoke(0xfoo,1): means that KYC admin revokes the SBT certificate number 1 for the address '0xfoo'.

    function revoke(address certifying, uint256 SBFID) external returns (bool);
```

**Events**

```solidity
pragma solidity ^0.8.0;
/** 
    * standardChanged
    * @notice standardChanged MUST be triggered when requirements are changed by the admin. 
    * @dev standardChanged MUST also be triggered for the creation of a new SBTID.
    e.g : emit standardChanged(1,Requirement(Metadata('depositRequirement','number', 'defines the max deposited that user can have in denomination of USDC' ), "<=", "30000");
    defines that holder of the identifier has been changed to the condition which allows the certificate holder to call the functions with modifier , only after the deposit in the address is not greater than 30000 USDC.
    */
    event standardChanged(uint256 SBTID, Requirement[] _requirement);
    /** 
    * certified
    * @notice certified MUST be triggered when SBT certificate is given to the certifiying address. 
    * eg: certified( 0xfoo,2); means that wallet holder address 0xfoo is certified to hold certificate issued with id 2 , and thus can satisfy all the confitions defined by the required interface.
    */
    event certified(address certifying, uint256 SBTID);
    /** 
    * revoked
    * @notice revoked MUST be triggered when SBT certificate is revoked. 
    * eg : revoked( 0xfoo,1); means that entity user 0xfoo has been revoked to all the function access defined by the the SBT ID 1.
    */
    event revoked(address certifying, uint256 SBTID);
```
## Rationale
We follow the structure of onchain metadata storage similar to that of [eip-3475](./eip-3475.md), except the fact that whole KYC requirement description is defined like the class from the eip-3475 standard but with only single condition. 

Following are the descriptions of the structures: 

**1.Metadata structure**: 

```solidity
    /**
     * @dev metadata that describes the Values structure on the given requirement. 
    example: 
    {   "title": "jurisdiction",
        "_type": "string",
        "description": "two word code defining legal jurisdiction"
        }
    * @notice it can be further optimise by using efficient encoding schemes (like TLV etc) and there can be tradeoff in the gas costs of storing large strings vs encoding/decoding costs while describing the standard.
     */
    struct Metadata {
        string title;
        string _type;
        string description;
    }
    
    /**
     * @dev Values here can be read and wrote by smartcontract and front-end, cited from [EIP-3475].
     example : 
{
 jurisdiction = Values.StringValue("CH");
}
     */
    struct Values { 
        string stringValue;
        uint uintValue;
        address addressValue;
        bool boolValue;
    }
```

**2.Requirement structure**:

This will be stored in each of the SBT certificate that will define the conditions that needs to be satisfied by the arbitrary address calling the `verify()` function, in order to be be validated as owner of the given certificate(ie following the regulations), this will be defined for each onchain Values separately.

```solidity

    /**
     * @dev structure that DeFines the parameters for specific requirement of the SBT certificate
     * @notice this structure is used for the verification process, it contains the metadata, logic and expectation
     * @logic given here MUST be one of ("⊄", "⊂", "<", "<=", "==", "!=", ">=",">")
     ex: standardRequirement => {
    { "title":"adult",
        "type": "uint",
        "description": "client holders age to be gt 18 yrs.",
        },
       "logic": ">=",
    "value":"18" 
}
Defines the condition encoded for the identity index 1, DeFining the identity condition that holder must be more than 18 years old.
    */
    struct Requirement {
        Metadata metadata;
        string logic;
        Values expectation;
    }

```

## Backwards Compatibility

The ERC standard remains backwards compliant for previous versions for cases that only do the changes in the requirements structure.

In case of the changes in the function logic, developers can use proxy contract patterns like [eip-1967](./eip-1967.md) which will route the validation condition based on the version of the contract.
## Test Cases

Test-case for the minimal reference implementation is [here](../assets/eip-zkID/contracts/test.sol) for using transaction verification regarding whether the users hold the tokens or not. Use the remix to compile and test the contracts.

## Reference Implementation
The interface standard is divided into two separated implementations.

- [verifier_modifier](../assets/eip-zkID/contracts/verification_modifier.sol) is the simple modifier that needs to be imported by the functions that are to be only called by holders of the SBT certificates. this essentially is wrapper contract of the eip `verify()`method and can also be implemented for arbitrary types of contract.

- [SBT_certification](../assets/eip-zkID/contracts/SBT_certification.sol) is the example of identity certificate that can be assigned by the KYC controller contract. this implements all th functions and events in the standard interface.


apart from that there is [example script](../assets/eip-zkID/script/createProof.js) that allows the creation of proofs off-chain and publish the proofs and specific public signatures onchain for the verification process.

## Security Considerations

1. Writing functions interfaces (i.e `changeStandardRequirement()`, `certify()` and `revoke()`) SHOULD be executed by admin roles in the SBT certificate contract as the getter functions (verify()) depends on the availablity of the necessary metadata to be immutable by any other non-admin entity.

2. The modifiers SHOULD not be deployed for the verifier contract that is upgradable (either via proxy patterns defined by [eip-1167](./eip-1167.md), [eip-1967](./eip-1967.md)). if the requirement is deemed important, there needs to be appropriate roles(usually by admin) in order to insure that verification logic doesn't get updated without the admin permission.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).