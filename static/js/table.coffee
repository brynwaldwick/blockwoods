React = require 'react'

Dispatcher = require './dispatcher'

{abiToWeb3} = require './eve'

# ABI describing table contract's interface
table_abi = [
    {
        "name": "deposit",
        "constant": false,
        "payable": true,
        "type": "function",
        "inputs": [],
        "outputs": []
    }
,
    {
        "name": "withdraw",
        "constant": false,
        "payable": false,
        "type": "function",
        "inputs": [{
            "name":"amount",
            "type":"uint256"
        }],
        "outputs": []
    }
,
    {
        "name": "resolveHand"
        "constant": false,
        "payable": false,
        "type": "function",
        "inputs": [{
            "name":"addresses",
            "type":"address[]"
        },{
            "name":"deltas",
            "type":"int[]"
        }],
        "outputs": []
    }
]

# bootstrap a dank human-readable interface
{deposit, withdraw, resolveHand} = abiToWeb3 table_abi

Table = React.createClass

    getInitialState: ->
        contract: null
        loading: true
        deposit: 0
        withdraw: 0

    componentDidMount: ->
        @contract$ = Dispatcher.getContract(@props.params.contract_address)
        @contract$.onValue @foundContract
        @logs$ = Dispatcher.contractLogs(@props.params.contract_address)
        @logs$.onValue @handleUpdate

    componentWillUnmount: ->
        @contract$.offValue @foundContract
        @logs$.offValue @handleUpdate

    foundContract: (contract) ->
        @setState {contract, loading: false}

    handleUpdate: (balance_update) ->
        _state = @state
        _state.contract?.balances?[balance_update.address] = balance_update.balance
        @setState _state

    deposit: ->
        deposit @props.params.contract_address, {value: 1000000}, (resp) ->
            console.log resp

    withdraw: ->
        withdraw @props.params.contract_address, 100000, {}, (resp) ->
            console.log resp

    render: ->

        <div>
            <h3>Table Contract Summary</h3>
            {if @state.loading
                <div className='loading'>loading...</div>
            else
                <div>
                    <div className='field'>
                        <label>buyin</label>
                        {@state.contract?.buyin}
                    </div>
                    <div className='field'>
                        <label>max_players</label>
                        {@state.contract?.max_players}
                    </div>
                    <div className='field'>
                        <label>num_players</label>
                        {@state.contract?.num_players}
                    </div>
                    <div className='field'>
                        <label>balances</label>
                        {Object.keys(@state.contract?.balances).map (addr, i) =>
                            <div className='balance' key=i>
                                {addr}:{' ' + @state.contract?.balances[addr]}
                            </div>
                        }
                    </div>
                    <div className='field'>
                        <label>pays</label>
                        {Object.keys(@state.contract?.pays).map (addr, i) =>
                            <div className='balance' key=i>
                                {addr}:{' ' + @state.contract?.pays[addr]}
                            </div>
                        }
                    </div>
                    <div className='button' onClick=@deposit >
                        deposit
                    </div>
                    <div className='button' onClick=@withdraw >
                        withdraw
                    </div>
                </div>
            }
        </div>

module.exports = Table