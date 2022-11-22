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
        factory = new MerkledropFactory(address(new Merkledrop()));
        murky = new Merkle();
        token = new MockERC20();
    }

    function testMerkledrop() public {
        address alice = address(0xAAAA);
        address bob = address(0xBBBB);

        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(alice, uint256(420 ether)));
        data[1] = keccak256(abi.encodePacked(bob, uint256(69 ether)));

        bytes32 root = murky.getRoot(data);

        token.mint(address(this), 420 ether + 69 ether);
        token.approve(address(factory), 420 ether + 69 ether);
        merkledrop = Merkledrop(
            factory.create(address(token), root, 420 ether + 69 ether)
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
        merkledrop.claim(aliceProof, 420.69 ether);

        // Ensure users cannot claim less than intended.
        vm.prank(alice);
        vm.expectRevert();
        merkledrop.claim(aliceProof, 420 ether - 0.69 ether);
        
        vm.prank(alice);
        merkledrop.claim(aliceProof, 420 ether);

        vm.prank(bob);
        merkledrop.claim(bobProof, 69 ether);

        // Ensure users cannot replay their claim.
        vm.prank(bob);
        vm.expectRevert();
        merkledrop.claim(bobProof, 69 ether);
    }
}
