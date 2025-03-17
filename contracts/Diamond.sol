// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol"; //interface modifying the facet in the diamond

contract Diamond {
    // crontract owner and address containing the facet implementation
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        // Creates an array cut of type IDiamondCut.FacetCut with one element.
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        // Creates an array functionSelectors of type bytes4 (used to store function selectors).
        bytes4[] memory functionSelectors = new bytes4[](1);

        // Adding the DiamondCut Function
        // Stores the function selector of diamondCut in functionSelectors[0].
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        // Populates cut[0]
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        //  Executing the Diamond Cut
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        // Retrieves Diamond storage.
        // Uses assembly to get storage at DIAMOND_STORAGE_POSITION (defined in LibDiamond).

        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        // Looks up the facet contract address for the called function (msg.sig).
        // If the function does not exist, it reverts with "Diamond: Function does not exist".
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");

        // Execute external function from facet using delegatecall and return any value.
        // Uses delegatecall to call the function in the facet contract.
        // If it fails, it reverts.
        // If it succeeds, it returns the function’s result.

        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    //immutable function example
    function example() public pure returns (string memory) {
        return "THIS IS AN EXAMPLE OF AN IMMUTABLE FUNCTION";
    }

    receive() external payable {}
}
