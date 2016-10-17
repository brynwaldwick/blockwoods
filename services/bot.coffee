somata = require 'somata'
config = require '../config'

SENDER = 'blockwoods-slot'
NEXUS_ACCOUNT_ID = config.nexus.account_id
nexus_client = new somata.Client {registry_host: config.nexus.host}
client = new somata.Client()

ContractsService = new somata.Client().bindRemote 'ethereum:contracts'
BlockwoodsEngine = client.bindRemote 'blockwoods:engine'

slot_address = config.slot_address
MIN_BET = 1000000000000;
MAX_BET = 1000000000000000;

pending_spins = {}

parseSender = (event) ->
    return event.sender.username

validateBetAmount = (amount) ->
    if amount < MIN_BET
        return false
    else if amount > MAX_BET
        return false
    else
        return true

sendNexusMessage = (body, type='message') ->
    response_message = {sender: SENDER, body, type}
    nexus_client.remote 'nexus:events', 'send', NEXUS_ACCOUNT_ID, response_message, -> # ...

nexus_client.subscribe 'nexus:events', "event:#{NEXUS_ACCOUNT_ID}:#{SENDER}", (event) ->
    console.log event

    sender = parseSender event
    switch sender
        when 'sean'
            account = '0xdde8f1b7a03a0135cec39e495d653f6ecfc305df'
        when 'chad'
            account = '0xaba83a7b118ecc13147151cf7c57e6c24f25e59f'
        when 'bryn'
            account = '0x82d1fb5b04f9280e3bfd816b4f5bde2f84fbdc0a'
        else
            return

    split_body = event.body.split(' ')

    if split_body[0] == 'balance'
        ContractsService 'getBalance', account, (err, resp) ->
            if resp?
                sendNexusMessage resp

    else if split_body[0] == 'pull'
        valid = validateBetAmount split_body[1]
        if !valid
            return sendNexusMessage "Please bet between #{MIN_BET} and #{MAX_BET} wei."

        ContractsService 'getParameter', 'OracleSlotMachine', slot_address, 'active', account, (err, active_bet) ->
            if active_bet
                sendNexusMessage 'You already have a bet active.'
            else
                ContractsService 'callFunction', 'OracleSlotMachine', slot_address, 'pullLever', {account, value: split_body[1]}, (err, resp) ->

                    sendNexusMessage 'Spinning...'
                    # wait for result and then broadcast result
                    client.on 'blockwoods:engine', "tx:#{resp}:done", (result) ->
                        sendNexusMessage "#{sender}, your result was #{result.s_1}, #{result.s_2}, #{result.s_3}"
                        # resolve pull
                        console.log "tx:#{result.outcome_tx}:done"
                        client.on 'blockwoods:engine', "tx:#{result.outcome_tx}:done", (result) ->
                            if result.result > 0
                                sendNexusMessage "WINNER! #{sender}, your bet was settled, paying #{result.result}:1"
                            else
                                sendNexusMessage "#{sender}, you lost. Keep gambling to try and win your money back."

    else if split_body[0] == 'pays'
        # query "pays" to see how much could be disbursed
        ContractsService 'callFunction', 'OracleSlotMachine', slot_address, 'pays', account, {account}, (err, resp) ->
            console.log err, resp
            sendNexusMessage resp

    else if split_body[0] == 'disburse'
        # do disbursal (send disburse from user's account)
        ContractsService 'callFunction', 'OracleSlotMachine', slot_address, 'disburse', '', {account}, (err, resp) ->
            console.log err, resp
            if !err?
                sendNexusMessage 'Disbursing...'

    else if split_body[0] == 'man'
        sendNexusMessage "balance - report the balance of your eve account \n" +
            "pull [bet_amount] - bet [bet_amount] and pull the slot's lever \n" +
            "pays - report the amount available to disburse \n" +
            "disburse - send your winnings to your address \n" +
            "man - man"
    else
        return

    # doThing event.body, (err, response) ->
        # sendNexusMessage err || response