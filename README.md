# Discographer

Discographer lists the back catalogues of artists in your iTunes library and highlights the ones you own.

Never miss an album by your favourite band!

---

### Usage

Discographer needs to be run locally to access to your iTunes library.

1. Clone the repo
2. Run `bundle install`
3. Fire up Middleman: `bundle exec middleman`
4. Visit [localhost:4567](http://localhost:4567)

---

### About

Discographer assumes your library is managed by iTunes, with albums sorted into folders by artist at `~/Music/iTunes/iTunes Media/Music`.

Albums are fetched through the [Spotify API](https://developer.spotify.com/web-api/). Add a `data/config.yml` based on the example to specify a country code for album availability (defaults to `US`). You can optionally supply [Spotify API credentials](https://developer.spotify.com/my-applications/) to improve speed.

### Todo

- [ ] Improve artist matching accuracy
- [ ] Think of a way to release publicly (users upload `iTunes Library.xml`?)