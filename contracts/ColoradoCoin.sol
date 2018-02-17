pragma solidity ^0.4.17;

import './EIP20.sol';

contract ColoradoCoin is EIP20 {

  function ColoradoCoin() EIP20(100000, "ColoradoCoin", 8, "COO") public {}

  function getMessage() public pure returns (bytes32) {
    bytes32 message = "ETHDenver is awesome!";
    return message;
  }

}