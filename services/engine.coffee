somata = require 'somata'

config = require '../config'

client = new somata.Client

random = (l=8) ->

getRandomIntInclusive = (min, max) ->
    min = Math.ceil(min)
    max = Math.floor(max)
    return Math.floor(Math.random() * (max - min + 1)) + min

ContractsService = client.bindRemote 'eth-dns:contracts'

handleSpin = (event_data, cb) ->
    result = getRandomIntInclusive 0, 27
    console.log result
    # TODO: submit result to wheel contract

    cb null, success: true