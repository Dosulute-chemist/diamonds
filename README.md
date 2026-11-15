# Diamond (EIP-2535) with an ERC20 Token Facet

This is my practice project for learning the Diamond pattern. It is the third project after my UUPS voting contract and my Transparent proxy lending contract.

I built a diamond with three facets, one of them an ERC20 token, and wrote Foundry tests to check that adding, replacing and removing functions works.

This is for learning only. The `LibDiamond` library is a simplified version of the standard's reference code, and nothing here has been audited.

## What it does

- **Diamond** (`src/Diamond.sol`): the proxy that users call. It keeps a table of function selector to facet address. Its `fallback()` looks up the selector and uses `delegatecall` to run that facet's code.
- **DiamondCutFacet** (`src/DiamondCutFacet.sol`): has `diamondCut`, which adds, replaces or removes functions. Only the owner can use it.
- **DiamondLoupeFacet** (`src/DiamondLoupeFacet.sol`): read-only functions that show which facets and functions the diamond has.
- **ERC20Facet** (`src/ERC20Facet.sol`): a simple token with transfer, approve, transferFrom and balances. Its data is kept at its own storage position, so it can't overwrite the diamond's table.
- **LibDiamond** (`src/LibDiamond.sol`): keeps the table and the owner, and holds the add, replace and remove logic.
- **IDiamondCut** (`src/IDiamondCut.sol`): the shape of one change (facet address, action, selectors).

## What I learned

- A normal proxy points to one implementation. A diamond points to many, called facets.
- Every function has a 4-byte selector, and the diamond maps each selector to a facet.
- To upgrade, I use `diamondCut` to add, replace or remove single functions, not a whole implementation.
- The data lives in the diamond, so facets must not clash. Each one keeps its data at its own hashed storage position (Diamond Storage).
- The facets have no storage of their own. They read and write the diamond's storage through `delegatecall`.
- Only the owner should be able to call `diamondCut`, or anyone could swap in a bad function.

## Tests

The tests are in `test/Diamond.t.sol`, written in Solidity with Foundry. They check that:

1. The loupe sees three facets.
2. A token transfer moves the balances.
3. Only the owner can call `diamondCut`.
4. A function that isn't in the table reverts.
5. Replacing `name()` works and the balances stay the same.
6. Removing `transfer` stops it from working.

## Run it

You need Foundry installed.

```bash
forge build
forge test -vv
```

You should see 6 tests pass.

## Problems I ran into

- The Foundry installer failed with an HTTP2 error because my internet dropped. I ran it again with `--http1.1`.
- My terminal said `forge: command not found` until I added Foundry to my PATH.
- My folder was not a Foundry project yet, so `forge build` said "Nothing to compile". I fixed it with `forge init --force`.
- My `.sol` files were in the main folder, not in `src`, so Foundry ignored them.
- Some file names started with a small letter, which broke the imports.
- One file was cut off when I pasted a long block, so it compiled with an empty function. I rebuilt it in smaller parts.

## What's next

- A deploy script for a real testnet.
- Tests for `transferFrom` and for a failed `initERC20` call.
- Reading the reference implementation to compare it with my simplified library.

Built with Foundry and Solidity.

Bello David
