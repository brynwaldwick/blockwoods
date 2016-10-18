somata = require 'somata'
config = require '../config'

SENDER = 'blockwoods-roulette'
NEXUS_ACCOUNT_ID = config.nexus.account_id
nexus_client = new somata.Client {registry_host: config.nexus.host}
client = new somata.Client()

announce = require('nexus-announce')(config.announce)

ContractsService = new somata.Client().bindRemote 'ethereum:contracts'
BlockwoodsEngine = client.bindRemote 'blockwoods:engine'

table_address = config.table_address
topic_base = "blockwoods:roulette:#{table_address}"
MAX_BET = 100000000000000000

wei_to_ether = 1000000000000000000

pending_spins = {}

parseSender = (event) ->
    return event.sender.username

validateBetAmount = (amount) ->
    if amount > MAX_BET
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
                number = Number(resp) / wei_to_ether

                sendNexusMessage number.toString()

    else if split_body[0][0..2] == 'bet'
        bet_amount = Number(split_body[1]) * wei_to_ether
        bet_arg = split_body[2]
        valid = validateBetAmount bet_amount
        if !valid
            return sendNexusMessage "Please bet below #{MAX_BET/wei_to_ether} ether."

        bet_fn = split_body[0]
        bet_kind = split_body[0][3..]

        finishRoute = (err, resp) ->
            sendNexusMessage 'Betting...'

            data = {txid: resp}
            data.bet_kind = bet_kind
            data.amount = bet_amount
            data.amount_str = (bet_amount/wei_to_ether + ' eth')
            data.bet_fn = bet_fn
            data.bet_arg = bet_arg

            announce {type: 'bet', game: 'roulette', project: 'blockwoods', topic: topic_base, data}

            # wait for result and then broadcast result
            client.on 'blockwoods:engine', "tx:#{resp}:done", (result) ->
                sendNexusMessage "#{sender}, your #{bet_kind} bet was placed"
                # resolve pull
                console.log "tx:#{result.outcome_tx}:done"


        if bet_fn in ['betBlack', 'betOdd', 'betBlack', 'betLow']
            # TODO: validate bool
            ContractsService 'callFunction', 'RouletteTable', table_address, bet_fn, bet_arg, {account, value: bet_amount.toString(), gas: '220000'}, finishRoute
        else if bet_fn in ['betStraightUp', 'betStreet', 'betColumn', 'betSixLine', 'betDozen']
            ContractsService 'callFunction', 'RouletteTable', table_address, bet_fn, bet_arg, {account, value: bet_amount.toString(), gas: '220000'}, finishRoute

    else if split_body[0] == 'spin'
        ContractsService 'callFunction', 'RouletteTable', table_address, 'spinWheel', {account, value: '0', gas: '100000'}, (err, resp) ->

            sendNexusMessage 'Spinning...'
            # wait for result and then broadcast result
            client.on 'blockwoods:engine', "tx:#{resp}:done", (result) ->
                sendNexusMessage "#{sender}, your result was #{result.n}"
                announce {type: 'play', game: 'roulette', project: 'blockwoods', topic: topic_base, data: {result, txid: result.outcome_tx}}
                # resolve pull
                console.log "tx:#{result.outcome_tx}:done"
                client.on 'blockwoods:engine', "tx:#{result.outcome_tx}:done", (result) ->

                    console.log 'the result was', result
                    if result.result > 0
                        sendNexusMessage "WINNER! #{sender}, your bet was settled, paying #{result.result}:1"
                    else
                        sendNexusMessage "#{sender}, you lost. Keep gambling to try and win your money back."

    else if split_body[0] == 'pays'
        # query "pays" to see how much could be disbursed
        ContractsService 'callFunction', 'RouletteTable', table_address, 'pays', account, {account}, (err, resp) ->
            console.log err, resp
            number = Number(resp) / wei_to_ether
            console.log number
            sendNexusMessage number.toString()

    else if split_body[0] == 'disburse'
        # do disbursal (send disburse from user's account)
        ContractsService 'callFunction', 'RouletteTable', table_address, 'disburse', {account, gas: '75000'}, (err, resp) ->
            console.log err, Number(resp)/wei_to_ether
            if !err?
                sendNexusMessage 'Disbursing...'

    else if split_body[0] == 'man'
        sendNexusMessage "balance - report the balance of your eve account \n" +
            "betStraightUp amount, uint  - bet on an exact number 0-37 (currently only allows one bet) \n" +
            "betBlack amount, bool - bet on black numbers according to https://en.wikipedia.org/wiki/Roulette#Bet_odds_table\n" +
            "betOdd amount, bool - bet on odd numbers \n" +
            "betLow amount, bool - bet on low numbers 1-18 (vs 19-36) \n" +
            "betColumn amount, uint - bet on column 1 (4, 7, 10...), 2 (5, 8, 11...), or 3 (6, 9, 12...) \n" +
            "betStreet amount, uint - bet on street 1 (2, 3), 4 (5, 6), 7 (8, 9), .... \n" +
            "betDozen amount, uint - bet on the 1st, 2nd or 3rd dozen (out of 36) \n" +
            "spin - spin the wheel \n" +
            "pays - report the amount available to disburse \n" +
            "disburse - send your winnings to your address \n" +
            "man - man"
    else
        return

    # doThing event.body, (err, response) ->
        # sendNexusMessage err || response