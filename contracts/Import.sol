// HACK TO MAKE TRUFFLE COMPILE CONTRACTS THAT ARENT IMPORTED

pragma solidity ^0.4.18;

import '@aragon/os/contracts/factory/DAOFactory.sol';
import '@aragon/os/contracts/factory/EVMScriptRegistryFactory.sol';
import '@aragon/os/contracts/acl/ACL.sol';
import '@aragon/os/contracts/kernel/Kernel.sol';

contract Import {}