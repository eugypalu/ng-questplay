// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Elegy1 {

    bytes32 public secondVerse;
    address public thirdVerse;
    bytes8 public firstVerse;
    uint128 public fourthVerse;
    uint96 public fifthVerse;

    function setVerse (
        bytes8 _firstVerse,
        bytes32 _secondVerse,
        address _thirdVerse,
        uint128 _fourthVerse,
        uint96 _fifthVerse
    ) external {
        firstVerse = _firstVerse;
        secondVerse = _secondVerse;
        thirdVerse = _thirdVerse;
        fourthVerse = _fourthVerse;
        fifthVerse = _fifthVerse;
    }

}