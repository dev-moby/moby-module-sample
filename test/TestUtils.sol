// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract TestUtils is Test {

    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_YEAR = 365 * SECONDS_PER_DAY;
    uint256 constant LEAP_YEAR_SECONDS = 366 * SECONDS_PER_DAY;
    
    function isLeapYear(uint16 year) private pure returns (bool) {
        if (year % 4 == 0) {
            if (year % 100 == 0) {
                return year % 400 == 0;
            } else {
                return true;
            }
        }
        return false;
    }

    function getDaysInMonth(uint8 month, uint16 year) private pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (month == 2) {
            return isLeapYear(year) ? 29 : 28;
        }
        revert("Invalid month");
    }

    function getTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint40) {
        require(year >= 1970, "Year must be after 1970");
        require(month >= 1 && month <= 12, "Invalid month");
        require(day >= 1 && day <= getDaysInMonth(month, year), "Invalid day");
        require(hour < 24, "Invalid hour");

        uint16 totalDays;
        for (uint16 i = 1970; i < year; i++) {
            totalDays += isLeapYear(i) ? 366 : 365;
        }

        for (uint8 i = 1; i < month; i++) {
            totalDays += getDaysInMonth(i, year);
        }
        totalDays += day - 1;

        return uint40(totalDays) * 24 * 60 * 60 + hour * 3600;
    }
    
    function getDate(uint40 _timestamp) public pure returns (uint16 year, uint8 month, uint8 day, uint8 hour) {
        year = 1970;
        uint256 timestamp = uint256(_timestamp);

        while (timestamp >= (isLeapYear(year) ? LEAP_YEAR_SECONDS : SECONDS_PER_YEAR)) {
            timestamp -= isLeapYear(year) ? LEAP_YEAR_SECONDS : SECONDS_PER_YEAR;
            year++;
        }

        for (month = 1; month <= 12; month++) {
            uint256 daysInMonth = getDaysInMonth(month, year) * SECONDS_PER_DAY;
            if (timestamp < daysInMonth) {
                break;
            }
            timestamp -= daysInMonth;
        }

        day = uint8(timestamp / SECONDS_PER_DAY) + 1;
        timestamp %= SECONDS_PER_DAY;
        hour = uint8(timestamp / SECONDS_PER_HOUR);
    }

    function uintToString(uint256 num) public pure returns (string memory) {
        return Strings.toString(num);
    } 

    function roundDown(uint256 num, uint256 precision) public pure returns (uint256) {
        return num / precision * precision;
    }
}
