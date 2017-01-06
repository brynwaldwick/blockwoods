React = require 'react'
ReactDOM = require 'react-dom'
moment = require 'moment'
# somata = require 'somata-socketio-client'

{Route, IndexRoute, Router, hashHistory, Link} = require 'react-router'
Table = require './table'

# Routes
# ------------------------------------------------------------------------------

routes =
    <Route path='/' component={AppView}>
        <Route path='/tables/:contract_address' component={Table} />
    </Route>

AppView = React.createClass

    render: ->
        console.log 'test test'
        <div>
            {@props.children}
        </div>
console.log 'test 21'
window.addEventListener 'load', ->

    web3 = window.web3

    # Checking if Web3 has been injected by the browser (Mist/MetaMask)
    if (typeof web3 == 'undefined')
        # Use Mist/MetaMask's provider
        web3 = new Web3 web3.currentProvider
        window.web3 = web3

ReactDOM.render(<Router routes={routes} history={hashHistory} />, document.getElementById('app'))
