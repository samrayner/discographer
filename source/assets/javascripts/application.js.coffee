#= require_tree ./vendor
#= require bootstrap
#= require_tree .

window.App ||= {}

class App.Main
  @API_ROOT: "https://api.spotify.com/v1"
  @AUTH_URL: "https://sr-spotify-auth.herokuapp.com"
  market: "US"
  library: {}
  artists: []
  authHeader: ""

  constructor: ->
    if window.navigator.platform.match(/mac/i) == null
      $path = $(".lib-path")
      $path.text($path.text().replace(/\//g, "\\"))

  geoSuccess: (location) =>
    @market = location.country.iso_code

  normalize: (string) ->
    string.toLowerCase().replace("&", "and").replace(/[^A-zÀ-ÿ\d\s]/g, "").replace(/\s+/g, " ").trim()

  processTrack: (artist, album) =>
    artistNorm = @normalize(artist)
    albumNorm = @normalize(album)
    if @library[artistNorm] == undefined
      index = @insertArtist(artist)
      @renderArtist(artist, artistNorm, index)
      @library[artistNorm] = [albumNorm]
    else if @library[artistNorm].indexOf(albumNorm) == -1
      @library[artistNorm].push(albumNorm)

  insertArtist: (artist) ->
    artist = artist.replace(/^the /i, "")
    @artists.push(artist)
    @artists.sort (a, b) ->
      a.localeCompare(b, 'en', { sensitivity: 'base' })
    @artists.indexOf(artist)

  renderArtist: (artist, artistNorm, index) ->
    $panel = $("<div class='panel panel-default' data-artist='#{artistNorm}' />")
    $heading = $("<div class='panel-heading'><strong>#{artist}<strong><span class='glyphicon glyphicon-chevron-down'></span></div>")
    $heading.click (event) => @headingClick(event, artistNorm)
    $panel.append($heading)

    if @artists.length == 0
      $("#output").append($panel)
    else if index == 0
      $("#output").prepend($panel)
    else
      $("#output .panel").eq(index-1).after($panel)

  toggleArrow: ($heading) ->
    $heading.find(".glyphicon").toggleClass("glyphicon-chevron-down glyphicon-chevron-up")

  headingClick: (event, artist) =>
    $target = $(event.currentTarget)
    @getArtist(artist)
    @toggleArrow($target)
    $target.off("click").click =>
      @toggleArrow($target)
      $target.parent().find(".list-group").toggleClass("hidden")

  getAccessToken: ->
    $ajax = $.ajax
      dataType: "text"
      type: "post"
      url: App.Main.AUTH_URL
    $ajax.done (data) =>
      @authHeader = "Bearer #{data}"

  getArtist: (name) =>
    url = "#{App.Main.API_ROOT}/search/?q=artist:#{encodeURIComponent(name)}&type=artist&market=#{@market}"
    $ajax = $.ajax
      dataType: "json"
      url: url
      headers:
        Authorization: @authHeader
    $ajax.done (data) =>
      artists = data.artists.items
      if artists.length == 0
        @renderError(name)
      else
        artist = artists[0]
        for art in artists
          if @normalize(art.name) == name
            artist = art
            break
        @getAlbumsForArtist(artist.id, name, artist.name)

  getAlbumsForArtist: (id, name, apiName) ->
    url = "#{App.Main.API_ROOT}/artists/#{id}/albums?album_type=album&market=#{@market}"
    $ajax = $.ajax
      dataType: "json"
      url: url
      headers:
        Authorization: @authHeader
    $ajax.done (data) =>
      names = []
      ids = []
      $.each data.items, (_, album) =>
        norm = @normalize(album.name)
        return if names.indexOf(norm) != -1
        ids.push(album.id)
        names.push(norm)
      if ids.length == 0
        @renderAlbums(ids, name, apiName)
      else
        @getAlbums(ids, name, apiName) if ids.length >= 1

  getAlbums: (ids, artist, apiArtist) =>
    url = "#{App.Main.API_ROOT}/albums?ids=#{ids.join(',')}"
    $ajax = $.ajax
      dataType: "json"
      url: url
      headers:
        Authorization: @authHeader
    $ajax.done (data) =>
      albums = data.albums.sort (a, b) =>
        @timestamp(a.release_date) - @timestamp(b.release_date)
      @renderAlbums(albums, artist, apiArtist)

  renderError: (artist) ->
    $ul = $("<ul class='list-group' />")
    $li = $("<li class='list-group-item list-group-item-danger'><span class='glyphicon glyphicon-exclamation-sign'></span> Artist not found on Spotify</li>")
    $ul.append($li)
    $(".panel[data-artist='#{artist}']").append($ul)

  renderAlbums: (albums, artist, apiArtist) ->
    $group = $("<ul class='list-group' />")

    if albums.length == 0
      $group.append("<li class='list-group-item list-group-item-danger'><span class='glyphicon glyphicon-exclamation-sign'></span> No albums found on Spotify</li>")
    else
      if artist != @normalize(apiArtist)
        $group.append("<li class='list-group-item list-group-item-warning'><span class='glyphicon glyphicon-info-sign'></span> Closest artist match: #{apiArtist}</li>")

    for album in albums
      $item = $("<a target='_blank' class='list-group-item' href='#{album.external_urls.spotify}' />")
      $art = $("<img class='album-art' src='#{album.images[0].url}' height='30' width='30' />")

      year = album.release_date.replace(/^(\d{4}).*/, '$1')
      $body = $("<p class='album-body'><span class='album-year'>#{year}</span>: #{album.name}</p>")

      if year == "#{new Date().getFullYear()}"
        $body.append(" <span class='label label-info'>New</span>")

      $item.append($art, $body)
      match = @library[artist].indexOf(@normalize(album.name)) != -1
      if match
        $item
          .addClass("list-group-item-success")
          .append("<span class='glyphicon glyphicon-ok' />")
      $group.append($item)

    $panel = $(".panel[data-artist='#{artist}']").append($group)

  timestamp: (string) ->
    (new Date(string)).valueOf()

  start: =>
    $.getJSON "http://ipinfo.io", (response) =>
      @market = response.country
    $("#landing").remove()

  stop: ->
    $(".progress").addClass("done")
    setTimeout (-> $(".progress").addClass("collapsed")), 1000
    $("#output").append("<div class='end-pad' />")

  updateProgress: (done, total) ->
    width = "#{Math.ceil(done/total*100)}%"
    $(".progress-bar").css("width", width)

  killEvent: (event) ->
    event.stopPropagation()
    event.preventDefault()

  dragEnter: (event) =>
    @killEvent(event)
    $("#landing").addClass("dragging")

  dragLeave: (event) =>
    @killEvent(event)
    $("#landing").removeClass("dragging")

  drop: (event) =>
    @dragLeave(event)

    unless window.File && window.FileList && window.FileReader
      return window.alert("Your browser does not support the File API")

    files = event.dataTransfer.files
    if files.length == 1 && files[0].type.match("text/xml") && files[0].name.match(/^iTunes (Music )?Library/) != null
      parser = new App.LibParser(files[0], @processTrack, @updateProgress, @stop)
      @start()
      parser.read()
    else
      window.alert("Drag your iTunes library here from\n/Users/USERNAME/Music/iTunes/iTunes Music Library.xml")

  init: ->
    @getAccessToken()
    dropzone = $("#dropzone").get(0)
    dropzone.addEventListener "dragenter", @dragEnter
    dropzone.addEventListener "dragleave", @dragLeave
    dropzone.addEventListener "drop",      @drop
    dropzone.addEventListener "dragover",  @killEvent

$ ->
  app = new App.Main()
  app.init()
