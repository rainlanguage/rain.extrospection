// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";

import "src/Extrospection.sol";

contract TestNoopooor {}

contract TestCreatooor {
    function justCreates() external {
        assembly ("memory-safe") {
            let c := create(0, 0, 0)
        }
    }
}

contract TestLog0ooor {
    function justLog0s() external {
        assembly ("memory-safe") {
            log0(0, 0)
        }
    }
}

contract TestLog1ooor {
    function justLog1s() external {
        assembly ("memory-safe") {
            log1(0, 0, 0)
        }
    }
}

contract TestLog2ooor {
    function justLog2s() external {
        assembly ("memory-safe") {
            log2(0, 0, 0, 0)
        }
    }
}

contract TestLog3ooor {
    function justLog3s() external {
        assembly ("memory-safe") {
            log3(0, 0, 0, 0, 0)
        }
    }
}

contract TestLog4ooor {
    function justLog4s() external {
        assembly ("memory-safe") {
            log4(0, 0, 0, 0, 0, 0)
        }
    }
}

contract ExtrospectionTest is Test {
    function testNoops() public {
        TestNoopooor noop = new TestNoopooor();

        Extrospection extrospection = new Extrospection();

        assertTrue(extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(noop)));
    }

    function testCreates() public {
        TestCreatooor tc = new TestCreatooor();

        Extrospection extrospection = new Extrospection();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(tc)));
    }
}
