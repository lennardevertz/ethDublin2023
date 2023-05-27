// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MyERC1155 is ERC1155 {
    // Mapping from token ID to account units
    mapping(uint256 => mapping(address => uint256)) private _units;

    constructor(string memory _uri) ERC1155(_uri) {
    }

    function mint(address account, uint256 tokenId, uint256 units) external {
        _mint(account, tokenId, 1, "");
        _units[tokenId][account] += units;
    }

    function unitsOf(address account, uint256 tokenId) public view virtual returns (uint256) {
        return _units[tokenId][account];
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override {

        // Call the super implementation for the transfer
        super.safeTransferFrom(from, to, tokenId, amount, data);

        uint256 unitsTransferred;
        unitsTransferred = _units[tokenId][from];
        
        _units[tokenId][from] -= unitsTransferred;
        _units[tokenId][to] += unitsTransferred;
    }

}
