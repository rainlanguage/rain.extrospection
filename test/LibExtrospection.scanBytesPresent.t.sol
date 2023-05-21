// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";

import "src/LibExtrospection.sol";

contract LibExtrospectionScanBytesPresentTest is Test {
    function testScanBytesPresent() public {
        assembly ("memory-safe") {
            mstore(0, hex"01020304")
        }

        uint256 scan = LibExtrospection.scanBytesPresent(Pointer.wrap(0), 4);

        console.log(scan);
    }
}
