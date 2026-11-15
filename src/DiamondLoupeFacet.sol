// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "./LibDiamond.sol";

contract DiamondLoupeFacet {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function facetAddress(bytes4 _selector) external view returns (address) {
        return LibDiamond.diamondStorage().selectorToFacet[_selector];
    }

    function facetAddresses() public view returns (address[] memory addrs) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 total = ds.selectors.length;
        address[] memory temp = new address[](total);
        uint256 count;
        for (uint256 i; i < total; i++) {
            address facet = ds.selectorToFacet[ds.selectors[i]];
            bool seen;
            for (uint256 j; j < count; j++) {
                if (temp[j] == facet) {
                    seen = true;
                    break;
                }
            }
            if (!seen) {
                temp[count] = facet;
                count++;
            }
        }
        addrs = new address[](count);
        for (uint256 k; k < count; k++) {
            addrs[k] = temp[k];
        }
    }

    function facetFunctionSelectors(address _facet) public view returns (bytes4[] memory result) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 total = ds.selectors.length;
        bytes4[] memory temp = new bytes4[](total);
        uint256 count;
        for (uint256 i; i < total; i++) {
            bytes4 selector = ds.selectors[i];
            if (ds.selectorToFacet[selector] == _facet) {
                temp[count] = selector;
                count++;
            }
        }
        result = new bytes4[](count);
        for (uint256 k; k < count; k++) {
            result[k] = temp[k];
        }
    }

    function facets() external view returns (Facet[] memory result) {
        address[] memory addrs = facetAddresses();
        result = new Facet[](addrs.length);
        for (uint256 i; i < addrs.length; i++) {
            result[i].facetAddress = addrs[i];
            result[i].functionSelectors = facetFunctionSelectors(addrs[i]);
        }
    }
}
