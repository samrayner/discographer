class LibParser
  chunkSize: 3000 #big enough to ecapsulate any track dict
  offset: 500 #skip down to track list in XML
  fileReader: new FileReader()
  file: null
  delimiter: "<key>Track ID</key>"
  library: {}

  constructor: (@file) ->
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
        @done()

  read: ->
    if @offset < @file.size
      slice = @file.slice(@offset, @offset + @chunkSize)
      @fileReader.readAsText(slice)
    else
      @done()

  valueForKeyInDoc: (key, doc) ->
    $key = $(doc).find("key").filter(-> $(this).text().toLowerCase() == key.toLowerCase())
    if $key.length >= 1
      $key.next().text()
    else
      undefined

  normalize: (string) ->
    string.toLowerCase().replace("&", "and").replace(/[^A-zÀ-ÿ\s]/g, "").replace(/\s+/g, " ").trim()

  parseTrack: (xml) ->
    doc = $.parseXML(xml)

    artist = @valueForKeyInDoc("album artist", doc)
    if artist == undefined
      artist = @valueForKeyInDoc("artist", doc)
    album = @valueForKeyInDoc("album", doc)
    bitRate = @valueForKeyInDoc("bit rate", doc)
    isAudioBook = @valueForKeyInDoc("genre", doc) == "Audiobook"

    if !isAudioBook && [artist, album, bitRate].indexOf(undefined) == -1
      artist = @normalize(artist)
      album = @normalize(album)

      if @library[artist] == undefined
        @library[artist] = [album]
      else if @library[artist].indexOf(album) == -1
        @library[artist].push(album)

  done: ->
    console.log(@library)

$ ->
  $("#file-input").change ->
    unless window.File && window.FileList && window.FileReader
      return window.alert("Your browser does not support the File API")

    files = this.files
    if files.length == 1 && files[0].type.match("text/xml")
      parser = new LibParser(files[0])
      parser.read()
    else
      window.alert("Please drop your iTunes Music Library.xml")
