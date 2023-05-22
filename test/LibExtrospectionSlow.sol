// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

library LibExtrospectionSlow {
    function scanEVMOpcodesPresentInMemorySlow(bytes memory data) internal pure returns (uint256) {
        uint256 scan = 0;
        for (uint256 i = 0; i < data.length; i++) {
            uint8 op = uint8(data[i]);
            scan = scan | (uint256(1) << uint256(op));

            if (0x60 <= op && op < 0x80) {
                i += op - 0x5f;
            }
        }
        return scan;
    }
}
