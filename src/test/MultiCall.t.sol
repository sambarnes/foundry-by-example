// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {MultiCall} from "../MultiCall.sol";

contract DutchAuctionTest is DSTestPlus {
    MultiCall private m;

    function setUp() public {
        m = new MultiCall();
    }

    //
    // Helpers
    //

    function someRevert(uint256 _i) external pure returns (uint256) {
        require(_i != _i, "always revert");
        return _i;
    }

    function someFunction(uint256 _i) external pure returns (uint256) {
        return _i;
    }

    function getCalldata(uint256 _i, bool reverts)
        external
        pure
        returns (bytes memory)
    {
        return
            reverts
                ? abi.encodeWithSelector(this.someRevert.selector, _i)
                : abi.encodeWithSelector(this.someFunction.selector, _i);
    }

    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    //
    // Cases
    //

    address[] _targets;
    bytes[] _calldata;

    function testMultiCallNone() public {
        bytes[] memory results = m.multiCall(_targets, _calldata);
        assertEq(0, results.length);
    }

    function testMultiCallSingle() public {
        _targets.push(address(this));
        _calldata.push(this.getCalldata(123, false));
        bytes[] memory results = m.multiCall(_targets, _calldata);

        assertEq(1, results.length);
        assertEq0(toBytes(123), results[0]);
    }

    function testMultiCallTriples() public {
        // triples is best
        _targets.push(address(this));
        _targets.push(address(this));
        _targets.push(address(this));
        _calldata.push(this.getCalldata(0, false));
        _calldata.push(this.getCalldata(1, false));
        _calldata.push(this.getCalldata(2, false));
        bytes[] memory results = m.multiCall(_targets, _calldata);

        assertEq0(toBytes(0), results[0]);
        assertEq0(toBytes(1), results[1]);
        assertEq0(toBytes(2), results[2]);
    }

    function testRevertSingle() public {
        _targets.push(address(this));
        _calldata.push(this.getCalldata(123, true));

        vm.expectRevert(bytes("call failed"));
        bytes[] memory results = m.multiCall(_targets, _calldata);
        assertEq(0, results.length);
    }

    function testRevertOneInThree() public {
        _targets.push(address(this));
        _targets.push(address(this));
        _targets.push(address(this));
        _calldata.push(this.getCalldata(123, false));
        _calldata.push(this.getCalldata(456, true));
        _calldata.push(this.getCalldata(789, false));

        vm.expectRevert(bytes("call failed"));
        bytes[] memory results = m.multiCall(_targets, _calldata);
        assertEq(0, results.length);
    }
}
