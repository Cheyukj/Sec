// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract WalletBeacon is UpgradeableBeacon {
    constructor(address implementation_) UpgradeableBeacon(implementation_) {

    }
}