// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "./IUSDC.sol";
import "./ERC20.sol";

import "../access/Ownable.sol";

contract MockUSDC is IUSDC, ERC20("USD Coin", "USDC"), Ownable {

    // keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32
        public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    // USDC on ArbitrumOne EIP-712 DomainSeparator (SM Addr: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831)
    // bytes32 public constant DOMAIN_SEPARATOR = 0x08d11903f8419e68b1b8721bcbe2e9fc68569122a77ef18c216f10b3b5112c78;

    // keccak256("USD Coin");
    bytes32 public constant NAME_HASH = 0x52878b207aaddbfc15ea7bebcda681eb8ccd306e2227b61cef68505c8c056341;

    // keccak256("2");
    bytes32 public constant VERSION_HASH = 0xad7c5bef027816a800da1736444fb58a807ef4c9603b7848673f7e3a68eb14a5;

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
    bytes32 public constant TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function domainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                TYPE_HASH,
                NAME_HASH,
                VERSION_HASH,
                block.chainid,
                address(this)
            )
        );
    }        

    // ---- Authorization ----

    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;

    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    // ---- Mint & Burn ----

    function mint(address to, uint amt) external onlyOwner {
        _mint(to, amt);
    }

    function burn(uint amt) external {
        _burn(msg.sender, amt);
    }

    // ---- TransferWithAuthorization ----

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {

        require(
            block.timestamp > validAfter,
            "FiatTokenV2: authorization is not yet valid"
        );

        require(
            block.timestamp < validBefore, 
            "FiatTokenV2: authorization is expired"
        );

        require(
            !_authorizationStates[from][nonce],
            "FiatTokenV2: authorization is used or canceled"
        );

        _requireValidSignature(
            from,
            keccak256(
                abi.encode(
                    TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
                    from,
                    to,
                    value,
                    validAfter,
                    validBefore,
                    nonce
                )
            ),
            v,
            r,
            s
        );

        _authorizationStates[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }

    function _requireValidSignature(
        address signer,
        bytes32 dataHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        require(
            _isValidSignatureNow(
                signer,
                _toTypedDataHash(dataHash),
                v,
                r,
                s
            ),
            "FiatTokenV2: invalid signature"
        );
    }

    function _toTypedDataHash(bytes32 structHash)
        internal
        view
        returns (bytes32 digest)
    {
        bytes32 separator = domainSeparator();
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), separator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }

    function _isValidSignatureNow(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        if (!_isContract(signer)) {
            return _recover(digest, v, r, s) == signer;
        }
        return false;
    }

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (address) {
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }

}