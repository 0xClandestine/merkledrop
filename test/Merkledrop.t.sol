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

    function testMerkledrop() public {
        address alice = address(0xAAAA);
        address bob = address(0xBBBB);

        uint256 aliceAmount = 420 ether;
        uint256 bobAmount = 69 ether;
        uint256 totalAirdrop = aliceAmount + bobAmount;

        // Define contents of merkle tree.
        bytes32[] memory data = new bytes32[](2);

        data[0] = keccak256(abi.encodePacked(alice, uint256(aliceAmount)));
        data[1] = keccak256(abi.encodePacked(bob, uint256(bobAmount)));

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

        // Create proofs
        bytes32[] memory aliceProof = murky.getProof(data, 0);
        bytes32[] memory bobProof = murky.getProof(data, 1);

        // Ensure users cannot claim more than intended.
        vm.prank(alice);
        vm.expectRevert();
        merkledrop.claim(aliceProof, aliceAmount + 1);

        // Ensure users cannot claim less than intended.
        vm.prank(alice);
        vm.expectRevert();
        merkledrop.claim(aliceProof, aliceAmount - 1);

        // Ensure alice can claim as expected.
        vm.prank(alice);
        merkledrop.claim(aliceProof, aliceAmount);

        // Ensure bob can claim as expected.
        vm.prank(bob);
        merkledrop.claim(bobProof, bobAmount);

        // Ensure users cannot replay their claim.
        vm.prank(bob);
        vm.expectRevert();
        merkledrop.claim(bobProof, bobAmount);
    }

    function testMerkledropNative() public {
        address alice = address(0xAAAA);
        address bob = address(0xBBBB);

        uint256 aliceAmount = 420 ether;
        uint256 bobAmount = 69 ether;
        uint256 totalAirdrop = aliceAmount + bobAmount;

        // Define contents of merkle tree.
        bytes32[] memory data = new bytes32[](2);

        data[0] = keccak256(abi.encodePacked(alice, uint256(aliceAmount)));
        data[1] = keccak256(abi.encodePacked(bob, uint256(bobAmount)));

        // Caclulate merkle root.
        bytes32 root = murky.getRoot(data);

        // Give this contract some test ether to create a merkledrop.
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

        // Create proofs
        bytes32[] memory aliceProof = murky.getProof(data, 0);
        bytes32[] memory bobProof = murky.getProof(data, 1);

        // Ensure users cannot claim more than intended.
        vm.prank(alice);
        vm.expectRevert();
        merkledrop.claim(aliceProof, aliceAmount + 1);

        // Ensure users cannot claim less than intended.
        vm.prank(alice);
        vm.expectRevert();
        merkledrop.claim(aliceProof, aliceAmount - 1);

        // Ensure alice can claim as expected.
        vm.prank(alice);
        merkledrop.claim(aliceProof, aliceAmount);

        // Ensure bob can claim as expected.
        vm.prank(bob);
        merkledrop.claim(bobProof, bobAmount);

        // Ensure users cannot replay their claim.
        vm.prank(bob);
        vm.expectRevert();
        merkledrop.claim(bobProof, bobAmount);
    }
}
