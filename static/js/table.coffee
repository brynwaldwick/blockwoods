React = require 'react'

Dispatcher = require './dispatcher'

Table = React.createClass

    getInitialState: ->
        contract: null
        loading: true

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

    render: ->
        console.log 'test'
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
                </div>
            }
        </div>

module.exports = Table