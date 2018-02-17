import React, { Component } from 'react';
import logo from './logo.svg';
import './assets/css/bootstrap.min.css';
import './App.css';
import ELECTION_SYSTEM_ABI from './assets/electionsystem.abi.json';
import ELECTION_SYSTEM_ADDRESS from './assets/electionsystem.address.json';
import { AragonApp, Countdown } from '@aragon/ui';
import { Table, TableHeader, TableRow, TableCell, Text, CircleGraph } from '@aragon/ui'

const DAY_IN_MS = 1000 * 60 * 60 * 24
const endDate = new Date(Date.now() + 5 * DAY_IN_MS);

class App extends Component {
  
  handleNewElection() {
    let contract = web3.eth.contract(ELECTION_SYSTEM_ABI).at(ELECTION_SYSTEM_ADDRESS.address)
    console.log(contract);
  }

  render() {
    console.log(ELECTION_SYSTEM_ABI, ELECTION_SYSTEM_ADDRESS);
    return (
      <div className="App container">
        <div className="row">
          <h4>Elections</h4>
          <div className="col-10 float-right">
            <button className="float-right btn btn-primary" onClick={ this.handleNewElection } >New Election</button>
          </div>
        </div>
        
        <h3 className="text-center"></h3>
        <Table
          header={
            <TableRow>
              <TableHeader title="Time Remaining" />
              <TableHeader title="Description" />
              <TableHeader title="" />
              <TableHeader title="" />
            </TableRow>
          }
        >
          <TableRow>
            <TableCell>
              <Text>
                <Countdown end={endDate} />
              </Text>
            </TableCell>
            <TableCell>
              <Text>Lorem Ipsum Dolor Ethereum</Text>
            </TableCell>
            <TableCell>
              <Text><CircleGraph value={1 / 3} /></Text>
            </TableCell>
            <TableCell>
              <div>Vote Yay</div>
              <div>Nay</div>

            </TableCell>
          </TableRow>
        </Table>



        <h3 className="text-center"></h3>
        <Table
          header={
            <TableRow>
              <TableHeader title="Time Remaining" />
              <TableHeader title="Description" />
              <TableHeader title="Total Votes" />
              <TableHeader title="Result" />
            </TableRow>
          }
        >
          <TableRow>
            <TableCell>
              <Text>
                <Countdown end={endDate} />
              </Text>
            </TableCell>
            <TableCell>
              <Text>Lorem Ipsum Dolor Ethereum</Text>
            </TableCell>
            <TableCell>
              <Text>60000</Text>
            </TableCell>
            <TableCell>
              <Text>Denied</Text>
            </TableCell>
          </TableRow>
        </Table>

      </div>
    );
  }
}

export default App;
