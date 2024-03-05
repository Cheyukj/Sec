// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
pragma solidity ^0.8.4;

import "./WalletProxyWithBeacon.sol";
import "./WalletImplementationV3.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract WalletFactoryImplementationV2 is AccessControlUpgradeable {

    using AddressUpgradeable for address;
    struct WalletInfo {
        address wallet;
        address owner;
        bytes32 salt;
    }

    event CreateWallet(bytes32 salt, address wallet);

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    //注意：walletBeacon 字段永远不可修改 CYY:标识特定钱包的唯一标识符或信息
    address public walletBeacon;

    function initialize(address beacon) public initializer() {

        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);

        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        walletBeacon = beacon;
    }

    function createWallet(
        address walletOwner, 
        bytes32 salt
    ) public onlyRole(ADMIN_ROLE) returns(address) {

        bytes memory constructorArgs = abi.encode(walletBeacon, "");

        bytes memory bytecode = abi.encodePacked(type(WalletProxyWithBeacon).creationCode, constructorArgs);
        
        address wallet;
        assembly {

            wallet := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(wallet)) {
                revert(0, 0)
            }
        }

        WalletImplementationV3(payable(wallet)).initialize(walletOwner);

        emit CreateWallet(salt, wallet);
        return wallet;
    }

    /**
    * @dev 查询bytecode hash
    */
    function calcBytecodeHash() view public returns(bytes32 ) {

        require(walletBeacon != address(0), "WalletFactoryImplementation: walletBeacon is not initialized");
        bytes memory constructorArgs = abi.encode(walletBeacon, "");
        bytes memory bytecode = abi.encodePacked(type(WalletProxyWithBeacon).creationCode, constructorArgs);
        bytes32  bcHash =  keccak256(bytecode);
        return bcHash;
    }

    /**
    * @dev 计算合约地址
    */
    function calculateAddress(bytes32 salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                calcBytecodeHash()
            )
        );
        return address(uint160(uint256(hash)));
    }

    /**
    * @dev 归集ETH
    */
    function transferEth(WalletInfo[] calldata froms, address to, uint[] calldata values) external onlyRole(ADMIN_ROLE) {
        require(froms.length == values.length, " WalletFactoryImplementation: patam is error");
        for (uint i = 0; i < froms.length; ++i) {
            if (!froms[i].wallet.isContract()) {
                address wallet;
                wallet = createWallet(froms[i].owner, froms[i].salt);
                require(wallet == froms[i].wallet, "WalletFactoryImplementation: input address not equal deployed address");
            }
            WalletImplementationV3(payable(froms[i].wallet)).transferETH(payable(to), values[i]);
        }
    }

    /**
    * @dev 归集erc20
    */
    function transferErc20(address token, WalletInfo[] calldata froms, address to, uint[] calldata values) external onlyRole(ADMIN_ROLE) {
        require(froms.length == values.length, " WalletFactoryImplementation: patam is error");
        for (uint i = 0; i < froms.length; ++i) {
            if (!froms[i].wallet.isContract()) {
                address wallet;
                wallet = createWallet(froms[i].owner, froms[i].salt);
                require(wallet == froms[i].wallet, "input address not equal deployed address");
            }
            WalletImplementationV3(payable(froms[i].wallet)).transferTokenErc20(token, to, values[i]);
        }
    }
    
    /**
    * @dev 转账erc721
    */
    function transferErc721(address token, WalletInfo calldata from, address to, uint tokenId) external onlyRole(ADMIN_ROLE) {
        if (!from.wallet.isContract()) {
            address wallet;
            wallet = createWallet(from.owner, from.salt);
            require(wallet == from.wallet, "input address not equal deployed address");
        }
        WalletImplementationV3(payable(from.wallet)).transferNFTErc721(IERC721Upgradeable(token), to, tokenId);
    }

    /**
    * @dev 归集erc1155
    */
    function transferErc1155(address token, WalletInfo[] calldata froms, address to, uint[] calldata tokenIds, uint[] calldata amounts) external onlyRole(ADMIN_ROLE) {
        require(froms.length == tokenIds.length && tokenIds.length == amounts.length, " WalletFactoryImplementation: patam is error");
        for (uint i = 0; i < froms.length; ++i) {
            if (!froms[i].wallet.isContract()) {
                address wallet;
                wallet = createWallet(froms[i].owner, froms[i].salt);
                require(wallet == froms[i].wallet, "input address not equal deployed address");
            }
            WalletImplementationV3(payable(froms[i].wallet)).transferNFTErc1155(IERC1155Upgradeable(token), to, tokenIds[i], amounts[i]);
        }
    }


}