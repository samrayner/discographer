module Helpers
  def spotify_token
    return nil unless data.config
    id = data.config.spotify_client_id
    secret = data.config.spotify_client_secret
    if id && secret
      RSpotify::authenticate(id, secret)
      RSpotify.instance_variable_get(:@client_token)
    else
      nil
    end
  end

  def itunes_library
    dir_tree("#{Dir.home}/Music/iTunes/iTunes Media/Music")
  end

  def spotify_market
    if data.config && data.config.spotify_market
      data.config.spotify_market
    else
      "US"
    end
  end

  def dir_tree(path, recurse=true)
    dirs = recurse ? {} : []
    Dir.entries(path).each do |entry|
      dir = File.join(path, entry)
      if entry != '.' && entry != '..' && File.directory?(dir)
        if recurse
          dirs[entry] = dir_tree(dir, false)
        else
          dirs << entry
        end
      end
    end
    return dirs
  end
end
