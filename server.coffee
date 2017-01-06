somata = require 'somata'
polar = require 'somata-socketio'

Redis = require 'redis'
redis = Redis.createClient null, null

config = require './config'

client = new somata.Client()
ContractsService = client.remote.bind client, 'ethereum:contracts'

localsMiddleware = (req, res, next) ->
    Object.keys(config._locals).map (_l) ->
        res.locals[_l] = config._locals[_l]
    res.locals.domain = config.domain
    next()

app = polar config.app, middleware: [localsMiddleware]

app.get '/', (req, res) ->
    console.log res.locals
    res.render 'base'

['info'].map (slug) ->
    app.get '/:slug', (req, res) ->
        res.render req.params.slug

app.get '/contracts/:contract_address.json', (req, res) ->
    {contract_address} = req.params
    ContractsService 'inspectContract', contract_address, (err, data) ->
        res.json data

app.get '/tables/:contract_address', (req, res) ->
    {contract_address} = req.params
    res.render 'base', {contract_address}

app.start()
