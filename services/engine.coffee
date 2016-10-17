somata = require 'somata'

config = require '../config'

client = new somata.Client

random = (l=8) ->

getRandomIntInclusive = (min, max) ->
    min = Math.ceil(min)
    max = Math.floor(max)
    return Math.floor(Math.random() * (max - min + 1)) + min

ContractsService = client.bindRemote 'blockwoods:contracts'

handleSpin = (event_data, cb) ->
    result = getRandomIntInclusive 0, 27
    console.log result
    # TODO: submit result to wheel contract
    {bettor} = event_data
    ContractsService 'sendSpinResult', bettor, result, (err, resp) ->
        service.publish "spins:#{bettor}:result"
        cb null, success: true

handlePullSlot = (event_data, cb) ->
    s_1 = getRandomIntInclusive 0, 9
    s_2 = getRandomIntInclusive 0, 9
    s_3 = getRandomIntInclusive 0, 9
    # TODO: submit result to wheel contract
    {bettor} = event_data
    ContractsService 'didPullSlot', bettor, s_1, s_2, s_3, (err, resp) ->
        console.log 'ill handle this', event_data
        service.publish "pulls:#{bettor}:result"
        service.publish "tx:#{event_data.event.transactionHash}:done", {s_1, s_2, s_3, outcome_tx: resp}
        cb null, success: true

pullLeverDone = (event_data, cb) ->
    console.log 'wonk jones', "tx:#{event_data.event.transactionHash}:done"
    service.publish "tx:#{event_data.event.transactionHash}:done", event_data, cb

service = new somata.Service 'blockwoods:engine', {
    handleSpin
    handlePullSlot
    pullLeverDone
}