log     = require 'simplog'
fs      = require 'fs'
path    = require 'path'
mkdirp  = require 'mkdirp'

# used to help make temp paths for allowing writes into the store itself
# to be atomic
tempCounter = 0

pathForKey = (key) ->
  path.join key[0..1], key[2..3], key

tempPathForKey = (key) ->
  keyPath = pathForKey key
  "#{keyPath}.#{process.pid}#{tempCounter++}"

class FileStorageProvider
  constructor: (@rootPath) ->
    if not fs.existsSync(@rootPath)
      # yes, this is fatal
      throw new Error "non existant storage root: #{@rootPath}"
    
  load:   (key, pipeHere, cb) =>
    storagePath = path.join @rootPath, pathForKey(key)
    readStream = fs.createReadStream(storagePath, encoding: 'utf8')
    readStream.on 'error', (err) ->
      if err.code is 'ENOENT'
        # file doesn't exist and this is something we 
        # explicitly don't care about
        cb null, false
      else
        log.error "error during load of #{key}, ", err
        cb err
    readStream.on 'end', () -> cb null, true
    readStream.pipe(pipeHere)

  delete: (key, cb) =>
    storagePath = path.join @rootPath, pathForKey(key)
    fs.unlink storagePath, (err) ->
      if err
        if err.code is 'ENOENT'
          # file doesn't exist and this is something we 
          # explicitly don't care about
          cb null, false
        else
          log.error "error during delete of #{key}, ", err
          cb err
      else
        cb null, true

  store:  (key, data, cb) =>
    tempPath = path.join @rootPath, tempPathForKey(key)
    finalPath = path.join @rootPath, pathForKey(key)
    mkdirp path.dirname(tempPath), (err) ->
      if err
        log.error "error during storage of #{key}, ", err
        cb err
      else
        fs.writeFile tempPath, data, (err) ->
          if err
            log.error "error writing temp data for key #{key}"
            cb err
          else
            fs.rename tempPath, finalPath, (err) ->
              if err
                log.error "error moving to final location for key #{key}"
              cb err
            

module.exports = FileStorageProvider
