// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WalletImplementationV3 
    is OwnableUpgradeable, 
    IERC721ReceiverUpgradeable, 
    IERC1155ReceiverUpgradeable {

    address public admin;

    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || admin == _msgSender(), "Ownable: caller is not the owner or admin");
        _;
    }

    function updateAdmin(address admin_) onlyOwner() public {
        admin = admin_;
    }

    function initialize(
        address walletOwner
    ) public initializer() {

        require(walletOwner != address(0), "WalletImplementation: walletOwner is the zero address");

        _transferOwnership(walletOwner);

        admin = _msgSender();
    }

    function transferETH(
        address payable to, 
        uint amount
    ) public onlyOwnerOrAdmin() {

        require(to != address(0), "WalletImplementation: to is zero");
        require(amount > 0, "WalletImplementation: amount is zero");
        require(address(this).balance >= amount, "WalletImplementation: Insufficient ETH balance");

        to.transfer(amount);
    }

    function transferTokenErc20(
        address assetContract, 
        address to, 
        uint amount
    ) public onlyOwnerOrAdmin() {
        
        require(address(assetContract).code.length > 0, "WalletImplementation: assetContract is not contract");
        require(amount > 0, "WalletImplementation: amount is zero");
        SafeERC20.safeTransfer(IERC20(assetContract), to, amount);
        
    }

    function transferNFTErc721(
        IERC721Upgradeable assetContract, 
        address to, uint tokenId
    ) public onlyOwnerOrAdmin() {

        require(address(assetContract).code.length > 0, "WalletImplementation: assetContract is not contract");
        assetContract.safeTransferFrom(address(this), to, tokenId);
    }

    function transferNFTErc1155(
        IERC1155Upgradeable assetContract, 
        address to, 
        uint tokenId, 
        uint amount
    ) public onlyOwnerOrAdmin() {
        
        require(address(assetContract).code.length > 0, "WalletImplementation: assetContract is not contract");
        require(amount > 0, "WalletImplementation: amount is zero");
        assetContract.safeTransferFrom(address(this), to, tokenId, amount,"");
    }

    function batchTransferNFTErc1155(
        IERC1155Upgradeable assetContract, 
        address to, 
        uint[] calldata tokenIds, 
        uint[] calldata amounts
    ) public onlyOwnerOrAdmin() {
        
        require(address(assetContract).code.length > 0, "WalletImplementation: assetContract is not contract");
        for (uint i = 0; i < amounts.length; ++i) {
            require(amounts[i] > 0, "WalletImplementation: amount is zero");
        }
        
        assetContract.safeBatchTransferFrom(address(this), to, tokenIds, amounts,"");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    )  public view returns (bool) {

        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
        interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ;
    }

    receive() external payable virtual {

    }

    /* ------------------------------------------ swap ------------------------------------------ */

    function swapExactTokensForTokens(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwnerOrAdmin() returns (uint256[] memory amounts) {
        if(IERC20(path[0]).allowance(address(this), router) != type(uint256).max){
            SafeERC20.safeApprove(IERC20(path[0]), router, type(uint256).max);
        }
        return IPancakeRouter02(router).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    function swapTokensForExactTokens(
        address router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwnerOrAdmin() returns (uint256[] memory amounts) {
        if(IERC20(path[0]).allowance(address(this), router) != type(uint256).max){
            SafeERC20.safeApprove(IERC20(path[0]), router, type(uint256).max);
        }
        return IPancakeRouter02(router).swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);
    }

    function swapExactETHForTokens(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external payable onlyOwnerOrAdmin() returns (uint256[] memory amounts) {
        return IPancakeRouter02(router).swapExactETHForTokens{value: amountIn}(amountOutMin, path, address(this), deadline);
    }

    function swapTokensForExactETH(
        address router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwnerOrAdmin() returns (uint256[] memory amounts) {
        if(IERC20(path[0]).allowance(address(this), router) != type(uint256).max){
            SafeERC20.safeApprove(IERC20(path[0]), router, type(uint256).max);
        }
        return IPancakeRouter02(router).swapTokensForExactETH(amountOut, amountInMax, path, address(this), deadline);
    }

    function swapExactTokensForETH(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwnerOrAdmin() returns (uint256[] memory amounts) {
        if(IERC20(path[0]).allowance(address(this), router) != type(uint256).max){
            SafeERC20.safeApprove(IERC20(path[0]), router, type(uint256).max);
        }
        return IPancakeRouter02(router).swapExactTokensForETH(amountIn, amountOutMin, path, address(this), deadline);
    }

    function swapETHForExactTokens(
        address router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external payable onlyOwnerOrAdmin() returns (uint256[] memory amounts) {
        return IPancakeRouter02(router).swapETHForExactTokens{value: amountInMax}(amountOut, path, address(this), deadline);
    }
    /* ------------------------------------------ swap ------------------------------------------ */
}