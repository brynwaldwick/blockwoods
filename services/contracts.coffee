async = require 'async'
somata = require 'somata'
Web3 = require 'web3'
SolidityCoder = require("web3/lib/solidity/coder.js")
eve = require '../../ethereum-sandbox/eve'

Redis = require 'redis'
redis = Redis.createClient null, null

config = require '../config'

SPINNER = config.spinner_address
ROULETTE = config.table_address

SLOT = config.slot_address

client = new somata.Client()
EngineService = client.bindRemote 'blockwoods:engine'

# Start web3
web3 = new Web3()
web3.setProvider(new web3.providers.HttpProvider("http://#{config.eth_ip}:8545"))

contract_schema =
    'RouletteTable': '../blockwoods/contracts/oraclized-roulette-table'
    'Spinner': '../blockwoods/contracts/oraclized-roulette-table'
    'LowBet': '../blockwoods/contracts/oraclized-roulette-table'
    'StraightUpBet': '../blockwoods/contracts/oraclized-roulette-table'
    'RouletteWheel': '../blockwoods/contracts/roulette-wheel'
    'RouletteWheelResolver': '../blockwoods/contracts/roulette-wheel'

    'SlotMachineLayout': '../blockwoods/contracts/slot-machine'
    'SlotMachineResolver': '../blockwoods/contracts/slot-machine'
    'OracleSlotMachine': '../blockwoods/contracts/slot-machine'

{sendTransaction, publishContract, getParameter, callFunction, compileContractData} = eve.buildGenericMethods contract_schema

processEvent =

    Spinner: (e) ->
        _data = SolidityCoder.decodeParams(["address", "string"], e.data.replace("0x",""))
        [bettor, message] = _data
        return {bettor, message, event: e}

    OracleSlotMachine: (e) ->
        if e.topics[0] == '0xdf2f43000ad262ff927c671ed83129f9054af075e5d3add03a2ba7116e719a51'
            kind = 'pull'
            _data = SolidityCoder.decodeParams(["address", "string"], e.data.replace("0x",""))
            [bettor, message] = _data
            return {kind, bettor, message, event: e}
        else
            kind = 'result'
            _data = SolidityCoder.decodeParams(["address", "uint"], e.data.replace("0x",""))
            [bettor, result] = _data
            return {kind, bettor, result, event: e}

Subscriptions = []

subscribeContract = (c) ->
    console.log c
    if c.address in Subscriptions
        return console.log 'Contract is already subscribed'
    else
        Subscriptions.push c.address

    web3.eth.getBlockNumber (err, block_no) ->
        console.log block_no
        contract_filter = web3.eth.filter({fromBlock:block_no, toBlock: 'latest', address: c.address})
        contract_filter.watch (err, result) ->
            console.log result, c
            _data = processEvent[c.type] result
            web3.eth.getBlock result.blockHash, (err, block) ->
                console.log "New event from #{c.type}", result
                console.log "Decoded to", _data
                if c.type == 'RouletteTable'
                    EngineService 'handleSpin', _data, (err, resp) ->
                        console.log err, resp
                else if c.type == 'OracleSlotMachine'
                    if _data.kind == 'pull'
                        EngineService 'handlePullSlot', _data, (err, resp) ->
                            console.log err, resp
                    else
                        console.log 'this is the result', _data

sendSpinResult = (bettor, result, cb) ->
    callFunction 'RouletteTable', ROULETTE, 'handleOutcome', bettor, result.toString(), {}, cb

didPullSlot = (bettor, args..., cb) ->
    callFunction 'OracleSlotMachine', SLOT, 'handleOutcome', bettor, args..., {value: 0, gas: 300000}, (err, resp) ->
        console.log err, resp
        cb err, resp

subscribeContract {address: config.spinner_address, type: 'Spinner'}
subscribeContract {address: config.slot_address, type: 'OracleSlotMachine'}

findContracts = (query, cb) ->
    redis.keys 'contracts:*', (err, keys) ->
        async.map keys, (k, _cb) ->
            redis.get k, (err, type) ->
                address = k.split(":")[1]
                _cb null, {address, type}
        , cb

service = new somata.Service 'blockwoods:contracts', {
    sendSpinResult
    didPullSlot
}
