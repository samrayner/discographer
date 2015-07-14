window.App ||= {}

class App.LibParser
  chunkSize: 3000 #big enough to ecapsulate any track dict
  offset: 500 #skip down to track list in XML
  fileReader: new FileReader()
  file: null
  delimiter: "<key>Track ID</key>"

  constructor: (@file, @newTrack, @progress=null, @done=null) ->
    @fileReader.addEventListener "load", (event) =>
      xml = event.target.result
      if xml.indexOf("<key>Size</key>") != -1
        if xml.indexOf(@delimiter) == 0
          xml = "<dict>#{xml.split("</dict>", 1)[0]}</dict>"
          @parseTrack(xml)
        @offset += xml.indexOf(@delimiter, 1)
        @read()
      else
        #reached playlist tracks
        @finished()

  read: ->
    if @offset < @file.size
      @progress(@offset, @file.size) if @progress != null
      slice = @file.slice(@offset, @offset + @chunkSize)
      @fileReader.readAsText(slice)
    else
      @finished()

  valueForKeyInDoc: (key, doc) ->
    $key = $(doc).find("key").filter(-> $(this).text().toLowerCase() == key.toLowerCase())
    if $key.length >= 1
      $key.next().text()
    else
      undefined

  parseTrack: (xml) ->
    doc = $.parseXML(xml)

    artist = @valueForKeyInDoc("album artist", doc)
    if artist == undefined
      artist = @valueForKeyInDoc("artist", doc)
    album = @valueForKeyInDoc("album", doc)
    bitRate = @valueForKeyInDoc("bit rate", doc)
    isAudioBook = @valueForKeyInDoc("genre", doc) == "Audiobook"

    if !isAudioBook && [artist, album, bitRate].indexOf(undefined) == -1
      @newTrack(artist, album)

  finished: ->
    @done() if @done != null
