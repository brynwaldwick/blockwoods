async = require 'async'
somata = require 'somata'

client = new somata.Client
{table_address} = require './config'

ContractsService = client.bindRemote 'ethereum:contracts'

ContractsService 'getParameter', 'RouletteTable', table_address, 'owner', (err, resp_1) ->
    ContractsService 'getParameter', 'RouletteTable', table_address, 'straight_up_bet', (err, straight_up) ->
        ContractsService 'getParameter', 'RouletteTable', table_address, 'odds', straight_up, (err, odds) ->
            # ContractsService 'getParameter', 'RouletteTable', table_address, 'pays', '0x82d1fb5b04f9280e3bfd816b4f5bde2f84fbdc0a', (err, pays) ->
                ContractsService 'getParameter', 'RouletteTable', table_address, 'amount_wagered', straight_up, (err, amt_wagered) ->
                    ContractsService 'getParameter', 'RouletteTable', table_address, 'pays', resp_1, (err, pays) ->
                        ContractsService 'getParameter', 'RouletteTable', table_address, 'available_values', straight_up, (err, amt_available) ->
                            # ContractsService 'getParameter', 'RouletteTable', table_address, 'pays', '0x82d1fb5b04f9280e3bfd816b4f5bde2f84fbdc0a', (err, resp_2) ->
                            console.log err, {resp_1, straight_up, odds, pays, amt_wagered, amt_available}
