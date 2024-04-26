// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MemoryLayout {

    /// @notice Create an uint256 memory array.
    /// @param size The size of the array.
    /// @param value The initial value of each element of the array.
    function createUintArray(
        uint256 size, 
        uint256 value
    ) public pure returns (uint256[] memory array) {
        assembly {

            let memIndex := mload(0x40)

            mstore(memIndex, size)

            array := memIndex

            memIndex := add(memIndex, 0x20)

            for { let i := 0 } lt(i,size) { i := add(i,1) } {
                mstore(memIndex, value)
                memIndex := add(memIndex, 0x20)
            }

              mstore(0x40, memIndex)

        }
    }

    /// @notice Create a bytes memory array.
    /// @param size The size of the array.
    /// @param value The initial value of each element of the array.
    function createBytesArray(
        uint256 size, 
        bytes1 value
    ) public pure returns (bytes memory array) {
        assembly {
            
            let memIndex := mload(0x40)

            mstore(memIndex, size)

            array := memIndex

            memIndex := add(memIndex, 0x20)

            for { let i := 0 } lt(i,size) { i := add(i,1) } {
                mstore(memIndex, value)
                memIndex := add(memIndex, 1)
            }

              mstore(0x40, memIndex)

        }
    }
}