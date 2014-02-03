#! /usr/bin/env ./node_modules/.bin/coffee
# vim:ft=coffee
 
express             = require 'express'
_                   = require 'lodash'
path                = require 'path'
log                 = require 'simplog'
http                = require 'http'
crypto              = require 'crypto'
FileStorageProvider = require('./src/fsp.coffee')

app = express()
app.use express.favicon()
app.use express.logger('dev')
app.use express.json()
app.use app.router
app.use express.errorHandler()

config =
  port: process.env.PORT || 8080
  storageConfig: process.env.STORAGE_PATH

app.set 'storageProvider', new FileStorageProvider config.storageConfig

NULL_DOCUMENT =
  message: "no document matching key"

createHash = (hashThis) ->
  cipher = crypto.createHash 'sha256'
  cipher.update hashThis
  cipher.digest 'hex'

createRequestData = (req) ->
  kvPath = req.path
  hash = createHash kvPath
  path: kvPath, key: hash

app.get /.*/, (req, res) ->
  rd = createRequestData req
  doc = app.get('storageProvider').load rd.key, res, (err, exists) ->
    if err
      res.send error: err
    else
      if exists
        res.end()
      else
        res.send NULL_DOCUMENT

app.delete /.*/, (req, res) ->
  rd = createRequestData req
  app.get('storageProvider').delete rd.key, (err, didDelete) ->
    if err
      res.send message: err, 500
    else
      if didDelete
        res.send message: "deleted"
      else
        res.send NULL_DOCUMENT

app.put /.*/, (req, res) ->
  rd = createRequestData req
  data = req.body
  if _.isEmpty data
    res.send message: "no data provided", 500
  else
    data = JSON.stringify data
    app.get('storageProvider').store rd.key, data, (err) ->
      if err
        res.send message: err
      else
        res.send message: "it's put"

log.info "server starting with configuration"
log.info "%j", config
server = http.createServer(app)
server.listen(config.port)
