#!/bin/bash

ganache-cli 2>&1 /dev/null &
sleep 5
truffle test
sleep 10
kill -9 $(lsof -t -i:8545)