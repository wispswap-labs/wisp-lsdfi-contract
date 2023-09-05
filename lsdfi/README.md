# WispSwap

## Structure

WispSwap Smart Contracts consists of 4 testnet sub-module:

-   `pool`: implementation module of Auto Market Maker (AMM) concept and return move object that must be handled by wrapper functions.
-   `router`: wrapper functions of swap_pool that implemented coins merging, type-checking and return objects handling.
-   `pool_utils`: helper functions for calculating neccessary informations.
-   `comparator`: comparating token types.

Besides, `swap_pool`also define a `Setting` object that holds all information of every pool

## Contract

### Current deployed contracts/objects

#### Devnet

-   Package address:
-   Setting object:

#### Testnet

-   Package address:
-   Setting object:

## Public API

Note:
Functions marked with:

-   `public` can call on-chain from other smart contract
-   `entry` can call off-chain using user wallet
-   `entry public` can also call on-chain and off-chain

## Error codes

Wispswap Error codes are grouped in five classes:

-   **4xx**: Token type errors
-   **5xx**: Numeric errors
-   **6xx**: Pool errors

### Full list

-   **401**: Type not sorted
-   **402**: Type equal - Same token
-   **501**: Amount equal to zero
-   **502**: Input balance less than input amount
-   **503**: Output amount less than minimum amount
-   **504**: Output amount greater than maximum amount
-   **505**: Output amount greater than pool reserve
-   **601**: Pool created
-   **602**: Pool not created
-   **603**: Pool reserve empty

Read more about Public API in `Docs`
