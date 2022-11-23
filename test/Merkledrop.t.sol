// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "solbase/tokens/ERC20/ERC20.sol";
import {Merkle} from "murky/Merkle.sol";
import {MerkledropFactory} from "../src/MerkledropFactory.sol";
import {Merkledrop} from "../src/Merkledrop.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("", "", 18) {}

    function mint(address guy, uint256 wad) public {
        _mint(guy, wad);
    }
}

contract MerkledropTest is Test {
    MerkledropFactory factory;
    Merkledrop merkledrop;
    Merkle murky;
    MockERC20 token;

    function setUp() public {
        factory = new MerkledropFactory(payable(address(new Merkledrop())));
        murky = new Merkle();
        token = new MockERC20();
    }

    function getAddress(bytes32 salt, uint256 index)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(abi.encode(salt, index)))));
    }

    function getAmount(bytes32 salt, uint256 index)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(salt, index))) % 100_000 ether;
    }

    function testMerkledrop(bytes32 salt, uint256 dataLen) public {
        vm.assume(dataLen < 100 && dataLen > 5);

        // Define contents of merkle tree.
        bytes32[] memory data = new bytes32[](dataLen);

        uint256 totalAirdrop;

        unchecked {
            for (uint256 i; i < dataLen; ++i) {
                uint256 amount = getAmount(salt, i);

                data[i] =
                    keccak256(abi.encodePacked(getAddress(salt, i), amount));

                totalAirdrop += amount;
            }
        }

        // Caclulate merkle root.
        bytes32 root = murky.getRoot(data);

        // Give this contract some test tokens to create a merkledrop.
        token.mint(address(this), totalAirdrop);
        token.approve(address(factory), totalAirdrop);
        merkledrop = Merkledrop(
            payable(factory.create(address(token), root, totalAirdrop))
        );

        // Ensure immutables were setup properly.
        assertEq(merkledrop.creator(), address(this));
        assertEq(merkledrop.asset(), address(token));
        assertEq(merkledrop.merkleRoot(), root);

        // Generate proofs
        bytes32[][] memory proofs = new bytes32[][](dataLen);

        unchecked {
            for (uint256 i; i < dataLen; ++i) {
                proofs[i] = murky.getProof(data, i);

                // Ensure address cannot claim more than intended.
                vm.prank(getAddress(salt, i));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(salt, i) + 1);

                // Ensure address cannot claim less than intended.
                vm.prank(getAddress(salt, i));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(salt, i) - 1);

                // Ensure address can claim as expected.
                vm.prank(getAddress(salt, i));
                merkledrop.claim(proofs[i], getAmount(salt, i));

                // Ensure address cannot replay claim.
                vm.prank(getAddress(salt, i));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(salt, i));
            }
        }
    }

    function testMerkledropNative(bytes32 salt, uint256 dataLen) public {
        vm.assume(dataLen < 100 && dataLen > 5);

        // Define contents of merkle tree.
        bytes32[] memory data = new bytes32[](dataLen);

        uint256 totalAirdrop;

        unchecked {
            for (uint256 i; i < dataLen; ++i) {
                uint256 amount = getAmount(salt, i);

                data[i] =
                    keccak256(abi.encodePacked(getAddress(salt, i), amount));

                totalAirdrop += amount;
            }
        }

        // Caclulate merkle root.
        bytes32 root = murky.getRoot(data);

        // Give this contract some test tokens to create a merkledrop.
        token.mint(address(this), totalAirdrop);
        token.approve(address(factory), totalAirdrop);
        merkledrop = Merkledrop(
            payable(
                factory.create{value: totalAirdrop}(
                    address(token), root, totalAirdrop
                )
            )
        );

        // Ensure immutables were setup properly.
        assertEq(merkledrop.creator(), address(this));
        assertEq(merkledrop.asset(), address(token));
        assertEq(merkledrop.merkleRoot(), root);

        // Generate proofs
        bytes32[][] memory proofs = new bytes32[][](dataLen);

        unchecked {
            for (uint256 i; i < dataLen; ++i) {
                proofs[i] = murky.getProof(data, i);

                // Ensure address cannot claim more than intended.
                vm.prank(getAddress(salt, i));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(salt, i) + 1);

                // Ensure address cannot claim less than intended.
                vm.prank(getAddress(salt, i));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(salt, i) - 1);

                // Ensure address can claim as expected.
                vm.prank(getAddress(salt, i));
                merkledrop.claim(proofs[i], getAmount(salt, i));

                // Ensure address cannot replay claim.
                vm.prank(getAddress(salt, i));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(salt, i));
            }
        }
    }
}
