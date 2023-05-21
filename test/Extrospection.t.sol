// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";

import "src/Extrospection.sol";

contract TestNoopooor {}

contract TestCreatooor {
    function justCreates() external {
        new TestNoopooor();
    }
}

contract ExtrospectionTest is Test {
    function testNoops() public {
        TestNoopooor noop = new TestNoopooor();

        Extrospection extrospection = new Extrospection();

        assertTrue(extrospection.interpreterAllowedOps(address(noop)));
    }

    function testCreates() public {
        TestCreatooor tc = new TestCreatooor();

        Extrospection extrospection = new Extrospection();

        assertTrue(!extrospection.interpreterAllowedOps(address(tc)));
    }
}
