// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FreeMemoryPointer {

    /// @notice Returns the value of the free memory pointer.
    function getFreeMemoryPointer() internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := mload(0x40)
        }
    }

    /// @notice Returns the highest memory address accessed so far.
    function getMaxAccessedMemory() internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := msize()
        }
    }

    /// @notice Allocates `size` bytes in memory.
    /// @return memoryAddress Address of start of allocated memory.
    function allocateMemory(uint256 size) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := mload(0x40) // Load the current free memory pointer
            mstore(0x40, add(memoryAddress, size)) // Update the free memory pointer
        }
    }

    /// @notice Frees the highest `size` bytes from memory.
    /// @dev Should revert if reserved space will be deallocated.
    function freeMemory(uint256 size) internal pure {
        assembly {
            let memoryAddress := mload(0x40)
            let newMemoryAddress := sub(memoryAddress, size)
            if lt(newMemoryAddress, 0x80) {revert (0,0)} 
            mstore(0x40,newMemoryAddress)
        }
    }
}