_ = require 'underscore'
Kefir = require 'kefir'
bus = require 'kefir-bus'
KefirCollection = require 'kefir-collection'
# somata = require 'somata-socketio-client'

fetch$ = require 'kefir-fetch'

Dispatcher =
    getContract: (contract_id) ->
        fetch$ 'get', "contracts/#{contract_id}.json"

    getContractABI: (contract_id) ->
        fetch$ 'get', "contracts/#{contract_id}/info.json"

    findContracts: () ->
        fetch$ 'get', "contracts.json"

    findAccounts: () ->
        accounts$ = fetch$ 'get', "accounts.json"
        accounts$.onValue (a) ->
            window.accounts = a

    createContract: (body) ->
        console.log body
        fetch$ 'post', "contracts.json", {body}

    sendCommand: (kind, body) ->
        fetch$ 'post', "commands.json", {body}

    alert$: bus()
    all_logs$: bus()

    showAlert: (alert) ->
        setTimeout -> # Run on next tick (after app subscribes to alerts)
            Dispatcher.alert$.emit alert
        , 0

    all_contracts$: KefirCollection()
    all_events$: KefirCollection()
    pending_transactions$: KefirCollection([], id_key: 'hash')

Dispatcher.pendingContractTransactions = (contract_addr) ->
    Dispatcher.pending_transactions$.filterItems (t) ->
        t.to == contract_addr

Dispatcher.contractLogs = (contract_addr) ->
    Dispatcher.all_logs$.filter (l) ->
        l.event.address == contract_addr

# somata.subscribe('ethereum:events', "all_events").onValue (data) ->
#     console.log 'got on here', data
#     Dispatcher.all_logs$.emit data

# somata.subscribe('ethereum:events', "all_contracts").onValue (data) ->
#     Dispatcher.all_contracts$.createItem data, true

# somata.subscribe('ethereum:contracts', "pending_calls").onValue (data) ->
#     # TODO: resolve "calls"/"contracts" vs "transactions"
#     Dispatcher.pending_transactions$.setItems data

module.exports = Dispatcher