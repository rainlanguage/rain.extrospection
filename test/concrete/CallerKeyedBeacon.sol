// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IBeacon} from "src/interface/IBeacon.sol";
import {IOwnable} from "src/interface/IOwnable.sol";

/// @dev Beacon test fixture that keys its answer off `msg.sender`.
/// `singledOut` gets `singledOutAnswer` from both `implementation()`
/// and `owner()`; every other caller gets `defaultAnswer`. Both
/// selectors share one pair of answers because the predicates under
/// test read one address each.
contract CallerKeyedBeacon is IBeacon, IOwnable {
    address public immutable singledOut;
    address public immutable defaultAnswer;
    address public immutable singledOutAnswer;

    constructor(address singledOut_, address defaultAnswer_, address singledOutAnswer_) {
        singledOut = singledOut_;
        defaultAnswer = defaultAnswer_;
        singledOutAnswer = singledOutAnswer_;
    }

    function implementation() external view returns (address) {
        return msg.sender == singledOut ? singledOutAnswer : defaultAnswer;
    }

    function owner() external view returns (address) {
        return msg.sender == singledOut ? singledOutAnswer : defaultAnswer;
    }
}
