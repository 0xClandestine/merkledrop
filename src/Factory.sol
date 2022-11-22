// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solbase/utils/SafeMulticallable.sol";
import "solbase/utils/SelfPermit.sol";
import "solbase/utils/SafeTransferLib.sol";
import "solbase/utils/LibClone.sol";

contract MerkledropFactory is SelfPermit, SafeMulticallable {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using LibClone for address;

    using SafeTransferLib for address;

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /// -----------------------------------------------------------------------
    /// Merkledrop Creation
    /// -----------------------------------------------------------------------

    function create(address erc20, bytes32 merkleRoot, uint256 totalAirdrop)
        external
        returns (address merkledrop)
    {
        bytes memory immutables = abi.encode(msg.sender, erc20, merkleRoot);

        merkledrop = implementation.clone(immutables);

        erc20.safeTransferFrom(msg.sender, merkledrop, totalAirdrop);
    }
}
