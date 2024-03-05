// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract WalletProxyWithBeacon is BeaconProxy {
    constructor(address beacon, bytes memory data) BeaconProxy(beacon, data) {
        //不需要admin，beacon初始化后永久不可修改。
    }

}