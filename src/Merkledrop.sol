// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solbase/utils/SafeTransferLib.sol";
import "solbase/utils/MerkleProofLib.sol";
import "solbase/utils/Clone.sol";

abstract contract ERC20 {
    function balanceOf(address) external view virtual returns (uint256);
}

contract Merkledrop is Clone {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;

    using MerkleProofLib for bytes32[];

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Claim(address account, uint256 amount);

    event Refunded(address to);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error InvalidProof();

    error CallerNotCreator();

    /// -----------------------------------------------------------------------
    /// Mutables
    /// -----------------------------------------------------------------------

    mapping(address => bool) public claimed;

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    function creator() public pure returns (address) {
        return _getArgAddress(12);
    }

    function erc20() public pure returns (address) {
        return _getArgAddress(44);
    }

    function merkleRoot() public pure returns (bytes32) {
        return bytes32(_getArgBytes(64, 32));
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function claim(bytes32[] calldata proof, uint256 value) external {
        bool valid = proof.verify(
            merkleRoot(), keccak256(abi.encodePacked(msg.sender, value))
        );

        if (valid && !claimed[msg.sender]) {
            claimed[msg.sender] = true;
            erc20().safeTransfer(msg.sender, value);
        } else {
            revert InvalidProof();
        }

        emit Claim(msg.sender, value);
    }

    /// @notice Allows creator to refund/remove all deposited funds.
    function refund(address to) external {
        if (msg.sender != creator()) revert CallerNotCreator();

        erc20().safeTransfer(to, ERC20(erc20()).balanceOf(address(this)));

        emit Refunded(to);
    }
}
