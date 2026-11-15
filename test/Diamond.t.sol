// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/DiamondLoupeFacet.sol";
import {ERC20Facet} from "../src/ERC20Facet.sol";
import {IDiamondCut} from "../src/IDiamondCut.sol";

// A tiny replacement facet, used to prove "replace" works
contract NameV2Facet {
    function name() external pure returns (string memory) {
        return "Upgraded Token";
    }
}

contract DiamondTest is Test {
    Diamond diamond;
    DiamondCutFacet cutFacet;
    DiamondLoupeFacet loupeFacet;
    ERC20Facet erc20Facet;
    address alice = address(0xA11CE);

    function setUp() public {
        cutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(cutFacet));
        loupeFacet = new DiamondLoupeFacet();
        erc20Facet = new ERC20Facet();

        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        _cut(address(loupeFacet), IDiamondCut.FacetCutAction.Add, loupeSelectors);

        bytes4[] memory tokenSelectors = new bytes4[](10);
        tokenSelectors[0] = ERC20Facet.name.selector;
        tokenSelectors[1] = ERC20Facet.symbol.selector;
        tokenSelectors[2] = ERC20Facet.decimals.selector;
        tokenSelectors[3] = ERC20Facet.totalSupply.selector;
        tokenSelectors[4] = ERC20Facet.balanceOf.selector;
        tokenSelectors[5] = ERC20Facet.allowance.selector;
        tokenSelectors[6] = ERC20Facet.initERC20.selector;
        tokenSelectors[7] = ERC20Facet.transfer.selector;
        tokenSelectors[8] = ERC20Facet.approve.selector;
        tokenSelectors[9] = ERC20Facet.transferFrom.selector;
        _cut(address(erc20Facet), IDiamondCut.FacetCutAction.Add, tokenSelectors);

        ERC20Facet(address(diamond)).initERC20("Diamond Token", "DMD", 1000 ether);
    }

    function _cut(address facet, IDiamondCut.FacetCutAction action, bytes4[] memory selectors) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut(facet, action, selectors);
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function test_LoupeShowsThreeFacets() public {
        address[] memory addrs = DiamondLoupeFacet(address(diamond)).facetAddresses();
        assertEq(addrs.length, 3);
    }

    function test_TokenTransfer() public {
        ERC20Facet token = ERC20Facet(address(diamond));
        assertEq(token.totalSupply(), 1000 ether);
        token.transfer(alice, 100 ether);
        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.balanceOf(address(this)), 900 ether);
    }

    function test_OnlyOwnerCanCut() public {
        bytes4[] memory sels = new bytes4[](1);
        sels[0] = ERC20Facet.name.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut(address(erc20Facet), IDiamondCut.FacetCutAction.Replace, sels);
        vm.prank(alice);
        vm.expectRevert("LibDiamond: Must be contract owner");
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function test_UnknownFunctionReverts() public {
        (bool ok,) = address(diamond).call(abi.encodeWithSignature("doesNotExist()"));
        assertFalse(ok);
    }

    function test_ReplaceFunctionKeepsData() public {
        ERC20Facet token = ERC20Facet(address(diamond));
        token.transfer(alice, 100 ether);

        NameV2Facet v2 = new NameV2Facet();
        bytes4[] memory sels = new bytes4[](1);
        sels[0] = ERC20Facet.name.selector;
        _cut(address(v2), IDiamondCut.FacetCutAction.Replace, sels);

        assertEq(token.name(), "Upgraded Token");
        assertEq(token.balanceOf(alice), 100 ether);
    }

    function test_RemoveFunction() public {
        bytes4[] memory sels = new bytes4[](1);
        sels[0] = ERC20Facet.transfer.selector;
        _cut(address(0), IDiamondCut.FacetCutAction.Remove, sels);

        (bool ok,) = address(diamond).call(abi.encodeWithSelector(ERC20Facet.transfer.selector, alice, 1 ether));
        assertFalse(ok);
        assertEq(DiamondLoupeFacet(address(diamond)).facetAddress(ERC20Facet.transfer.selector), address(0));
    }
}
