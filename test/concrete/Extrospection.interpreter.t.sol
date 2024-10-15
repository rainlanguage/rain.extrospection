// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {Extrospection} from "src/concrete/Extrospection.sol";

contract TestNoopooor {}

contract TestCreateooor {
    function justCreates() external {
        assembly ("memory-safe") {
            let c := create(0, 0, 0)
        }
    }
}

contract TestCreate2ooor {
    function justCreate2s() external {
        assembly ("memory-safe") {
            let c := create2(0, 0, 0, 0)
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

contract TestSStoreooor {
    function justSStores() external {
        assembly ("memory-safe") {
            sstore(0, 0)
        }
    }
}

contract TestSLoadooor {
    function justSLoads() external view returns (uint256 s) {
        assembly ("memory-safe") {
            s := sload(0)
        }
    }
}

contract TestSelfDestructooor {
    function justSelfDestructs() external {
        assembly ("memory-safe") {
            selfdestruct(0)
        }
    }
}

contract TestCallooor {
    function justCalls() external {
        assembly ("memory-safe") {
            let c := call(0, 0, 0, 0, 0, 0, 0)
        }
    }
}

contract TestDelegateCallooor {
    function justDelegateCalls() external {
        assembly ("memory-safe") {
            let c := delegatecall(0, 0, 0, 0, 0, 0)
        }
    }
}

contract TestCallCodeooor {
    function justCallCodes() external {
        assembly ("memory-safe") {
            let c := callcode(0, 0, 0, 0, 0, 0, 0)
        }
    }
}

contract ExtrospectionInterpreterTest is Test {
    // Testing noops is a control case.
    function testNoopooor() public {
        Extrospection extrospection = new Extrospection();
        TestNoopooor c = new TestNoopooor();

        assertTrue(extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testCreateooor() public {
        Extrospection extrospection = new Extrospection();
        TestCreateooor c = new TestCreateooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testCreate2ooor() public {
        Extrospection extrospection = new Extrospection();
        TestCreate2ooor c = new TestCreate2ooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testLog0ooor() public {
        Extrospection extrospection = new Extrospection();
        TestLog0ooor c = new TestLog0ooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testLog1ooor() public {
        Extrospection extrospection = new Extrospection();
        TestLog1ooor c = new TestLog1ooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testLog2ooor() public {
        Extrospection extrospection = new Extrospection();
        TestLog2ooor c = new TestLog2ooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testLog3ooor() public {
        Extrospection extrospection = new Extrospection();
        TestLog3ooor c = new TestLog3ooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testLog4ooor() public {
        Extrospection extrospection = new Extrospection();
        TestLog4ooor c = new TestLog4ooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testSStoreooor() public {
        Extrospection extrospection = new Extrospection();
        TestSStoreooor c = new TestSStoreooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testSLoadooor() public {
        Extrospection extrospection = new Extrospection();
        TestSLoadooor c = new TestSLoadooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testSelfDestructooor() public {
        Extrospection extrospection = new Extrospection();
        TestSelfDestructooor c = new TestSelfDestructooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testCallooor() public {
        Extrospection extrospection = new Extrospection();
        TestCallooor c = new TestCallooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testDelegateCallooor() public {
        Extrospection extrospection = new Extrospection();
        TestDelegateCallooor c = new TestDelegateCallooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }

    function testCallCodeooor() public {
        Extrospection extrospection = new Extrospection();
        TestCallCodeooor c = new TestCallCodeooor();

        assertTrue(!extrospection.scanOnlyAllowedInterpreterEVMOpcodes(address(c)));
    }
}
