// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDiamondCut} from "./IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => address) selectorToFacet;
        mapping(bytes4 => uint256) selectorIndex;
        bytes4[] selectors;
        address contractOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 i; i < _diamondCut.length; i++) {
            IDiamondCut.FacetCutAction action = _diamondCut[i].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            } else {
                removeFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facet, bytes4[] memory _selectors) internal {
        require(_selectors.length > 0, "LibDiamond: No selectors");
        require(_facet != address(0), "LibDiamond: Facet can't be zero address");
        require(_facet.code.length > 0, "LibDiamond: Facet has no code");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 i; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            require(ds.selectorToFacet[selector] == address(0), "LibDiamond: Selector already exists");
            ds.selectorToFacet[selector] = _facet;
            ds.selectorIndex[selector] = ds.selectors.length;
            ds.selectors.push(selector);
        }
    }

    function replaceFunctions(address _facet, bytes4[] memory _selectors) internal {
        require(_selectors.length > 0, "LibDiamond: No selectors");
        require(_facet != address(0), "LibDiamond: Facet can't be zero address");
        require(_facet.code.length > 0, "LibDiamond: Facet has no code");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 i; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            address oldFacet = ds.selectorToFacet[selector];
            require(oldFacet != address(0), "LibDiamond: Selector does not exist");
            require(oldFacet != _facet, "LibDiamond: Same facet already used");
            ds.selectorToFacet[selector] = _facet;
        }
    }

    function removeFunctions(address _facet, bytes4[] memory _selectors) internal {
        require(_selectors.length > 0, "LibDiamond: No selectors");
        require(_facet == address(0), "LibDiamond: Remove facet address must be zero");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 i; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            require(ds.selectorToFacet[selector] != address(0), "LibDiamond: Selector does not exist");
            uint256 index = ds.selectorIndex[selector];
            uint256 lastIndex = ds.selectors.length - 1;
            if (index != lastIndex) {
                bytes4 lastSelector = ds.selectors[lastIndex];
                ds.selectors[index] = lastSelector;
                ds.selectorIndex[lastSelector] = index;
            }
            ds.selectors.pop();
            delete ds.selectorIndex[selector];
            delete ds.selectorToFacet[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        require(_init.code.length > 0, "LibDiamond: Init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                assembly {
                    revert(add(error, 32), mload(error))
                }
            } else {
                revert("LibDiamond: Init function reverted");
            }
        }
    }
}