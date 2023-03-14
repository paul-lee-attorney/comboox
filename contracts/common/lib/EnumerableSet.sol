// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.8;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            delete set._values[lastIndex];
            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    //======== Bytes32Set ========

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        public
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        public
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        public
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set)
        public
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    //======== AddressSet ========

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        public
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        public
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        public
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        public
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    //======== UintSet ========

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) public returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        public
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        public
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) public view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        public
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set)
        public
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // =========================================================================

    /**
     * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
     * All Rights Reserved.
     ***/

    // shall be checked at front-end so as to avoid overflow
    // function valuesToUint8(UintSet storage set)
    //     public
    //     view
    //     returns (uint8[] memory)
    // {
    //     bytes32[] memory store = _values(set._inner);
    //     uint8[] memory result;

    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }

    // function valuesToUint16(UintSet storage set)
    //     public
    //     view
    //     returns (uint16[] memory)
    // {
    //     bytes32[] memory store = _values(set._inner);
    //     uint16[] memory result;

    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }
    
    // shall be checked at front-end so as to avoid overflow
    // function valuesToUint32(UintSet storage set)
    //     public
    //     view
    //     returns (uint32[] memory)
    // {
    //     bytes32[] memory store = _values(set._inner);
    //     uint32[] memory result;

    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }

    // shall be checked at front-end so as to avoid overflow
    // function valuesToUint40(UintSet storage set)
    //     public
    //     view
    //     returns (uint40[] memory)
    // {
    //     bytes32[] memory store = _values(set._inner);
    //     uint40[] memory result;

    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }

    // // shall be checked at front-end so as to avoid overflow
    // function valuesToUint88(UintSet storage set)
    //     public
    //     view
    //     returns (uint88[] memory)
    // {
    //     bytes32[] memory store = _values(set._inner);
    //     uint88[] memory result;

    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }

    function emptyItems(UintSet storage set) public {
        uint256 len = set._inner._values.length;

        while (len != 0) {
            _remove(set._inner, set._inner._values[len - 1]);
            len--;
        }
    }
}
