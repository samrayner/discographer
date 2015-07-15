#= require_tree ./vendor
#= require bootstrap
#= require_tree .

window.App ||= {}

class App.Main
  @API_ROOT: "https://api.spotify.com/v1"
  market: "US"
  library: {}
  artists: []

  constructor: ->
    if typeof geoip2 != 'undefined'
      geoip2.country @geoSuccess, null

    if window.navigator.platform.match(/mac/i) == null
      $path = $(".lib-path")
      $path.text($path.text().replace(/\//g, "\\"))

  geoSuccess: (location) =>
    @market = location.country.iso_code

  normalize: (string) ->
    string.toLowerCase().replace("&", "and").replace(/[^A-zÀ-ÿ\s]/g, "").replace(/\s+/g, " ").trim()

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
    @artists.sort()
    @artists.indexOf(artist)

  renderArtist: (artist, artistNorm, index) ->
    $col = $("<div class='col-sm-6 panel-wrapper' />")
    $panel = $("<div class='panel panel-default' data-artist='#{artistNorm}' />")
    $heading = $("<div class='panel-heading'><strong>#{artist}<strong><span class='glyphicon glyphicon-chevron-down pull-right'></span></div>")
    $heading.click => @headingClick(artistNorm)
    $panel.append($heading)
    $col.append($panel)

    if @artists.length == 0
      $("#output").append($col)
    else if index == 0
      $("#output").prepend($col)
    else
      $("#output .panel-wrapper").eq(index-1).after($col)

  toggleArrow: ($heading) ->
    $heading.find(".glyphicon").toggleClass("glyphicon-chevron-down glyphicon-chevron-up")

  headingClick: (artist) =>
    $target = $(event.target)
    @getArtist(artist)
    @toggleArrow($target)
    $target.unbind("click").click =>
      @toggleArrow($target)
      $target.parent().find(".list-group").toggleClass("hidden")

  getArtist: (name) =>
    url = "#{App.Main.API_ROOT}/search/?q=artist:#{encodeURIComponent(name)}&type=artist&limit=1&market=#{@market}"
    $.getJSON url, (data) =>
      artist = data.artists.items[0]
      if artist == undefined
        @renderError(name)
      else
        @getAlbumsForArtist(artist.id, name, artist.name)

  getAlbumsForArtist: (id, name, apiName) ->
    url = "#{App.Main.API_ROOT}/artists/#{id}/albums?album_type=album&market=#{@market}"
    $.getJSON url, (data) =>
      names = []
      ids = []
      $.each data.items, (_, album) =>
        norm = @normalize(album.name)
        return if album.name.toLowerCase().match(/\((deluxe|special)/) != null
        return if names.indexOf(norm) != -1
        ids.push(album.id)
        names.push(norm)
      if ids.length == 0
        @renderAlbums(ids, name, apiName)
      else
        @getAlbums(ids, name, apiName) if ids.length >= 1

  getAlbums: (ids, artist, apiArtist) =>
    url = "#{App.Main.API_ROOT}/albums?ids=#{ids.join(',')}"
    $.getJSON url, (data) =>
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
      $art = $("<img class='pull-right' src='#{album.images[0].url}' height='30' />")

      year = album.release_date.replace(/^(\d{4}).*/, '$1')
      $body = $("<p><span class='album-year'>#{year}</span>: #{album.name}</p>")

      if year == "#{new Date().getFullYear()}"
        $body.append(" <span class='label label-info'>New</span>")

      $item.append($art, $body)
      match = @library[artist].indexOf(@normalize(album.name)) != -1
      $item.addClass("list-group-item-success") if match
      $group.append($item)

    $(".panel[data-artist='#{artist}']").append($group)

  timestamp: (string) ->
    (new Date(string)).valueOf()

  start: =>
    $("#landing").remove()

  stop: ->
    $(".progress").addClass("done")
    setTimeout (-> $(".progress").addClass("collapsed")), 1000

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
    @killEvent(event)

    unless window.File && window.FileList && window.FileReader
      return window.alert("Your browser does not support the File API")

    files = event.dataTransfer.files
    if files.length == 1 && files[0].type.match("text/xml") && files[0].name.match(/^iTunes (Music )?Library/) != null
      parser = new App.LibParser(files[0], @processTrack, @updateProgress, @stop)
      @start()
      parser.read()
    else
      window.alert("Please drop your iTunes Library.xml")

  init: ->
    dropzone = $("#dropzone").get(0)
    dropzone.addEventListener "dragenter", @dragEnter
    dropzone.addEventListener "dragleave", @dragLeave
    dropzone.addEventListener "drop",      @drop
    dropzone.addEventListener "dragover",  @killEvent

$ ->
  app = new App.Main()
  app.init()
