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

    function getAddress(bytes32 hash) internal pure returns (address) {
        return address(uint160(uint256(hash)));
    }

    function getAmount(bytes32 hash) internal pure returns (uint256) {
        return uint256(hash) % 100_000_000 ether;
    }

    function testMerkledrop(bytes32 salt, uint256 dataLen) public {
        vm.assume(dataLen < 100 && dataLen > 5);

        // Define contents of merkle tree.
        bytes32[] memory data = new bytes32[](dataLen);

        uint256 totalAirdrop;

        unchecked {
            for (uint256 i; i < dataLen; ++i) {
                bytes32 hash = keccak256(abi.encode(salt, i));

                uint256 amount = getAmount(hash);

                data[i] = keccak256(abi.encodePacked(getAddress(hash), amount));

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

                bytes32 hash = keccak256(abi.encode(salt, i));

                // Ensure address cannot claim more than intended.
                vm.prank(getAddress(hash));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(hash) + 1);

                // Ensure address cannot claim less than intended.
                vm.prank(getAddress(hash));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(hash) - 1);

                // Ensure address can claim as expected.
                vm.prank(getAddress(hash));
                merkledrop.claim(proofs[i], getAmount(hash));

                // Ensure address cannot replay claim.
                vm.prank(getAddress(hash));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(hash));
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
                bytes32 hash = keccak256(abi.encode(salt, i));

                uint256 amount = getAmount(hash);

                data[i] = keccak256(abi.encodePacked(getAddress(hash), amount));

                totalAirdrop += amount;
            }
        }

        // Caclulate merkle root.
        bytes32 root = murky.getRoot(data);

        // Give this contract some test tokens to create a merkledrop.
        deal(address(this), totalAirdrop);
        merkledrop = Merkledrop(
            payable(
                factory.create{value: totalAirdrop}(
                    address(0), root, totalAirdrop
                )
            )
        );

        // Ensure immutables were setup properly.
        assertEq(merkledrop.creator(), address(this));
        assertEq(merkledrop.asset(), address(0));
        assertEq(merkledrop.merkleRoot(), root);

        // Generate proofs
        bytes32[][] memory proofs = new bytes32[][](dataLen);

        unchecked {
            for (uint256 i; i < dataLen; ++i) {
                proofs[i] = murky.getProof(data, i);

                bytes32 hash = keccak256(abi.encode(salt, i));

                // Ensure address cannot claim more than intended.
                vm.prank(getAddress(hash));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(hash) + 1);

                // Ensure address cannot claim less than intended.
                vm.prank(getAddress(hash));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(hash) - 1);

                // Ensure address can claim as expected.
                vm.prank(getAddress(hash));
                merkledrop.claim(proofs[i], getAmount(hash));

                // Ensure address cannot replay claim.
                vm.prank(getAddress(hash));
                vm.expectRevert();
                merkledrop.claim(proofs[i], getAmount(hash));
            }
        }
    }
}
