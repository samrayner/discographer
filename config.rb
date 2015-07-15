set :haml, { format: :html5, attr_wrapper: '"' }

set :css_dir, 'assets/stylesheets'
set :js_dir, 'assets/javascripts'
set :images_dir, 'assets/images'

configure :build do
  activate :minify_javascript
end

activate :deploy do |deploy|
  deploy.build_before = true
  deploy.method = :git
  deploy.remote = "origin"
  deploy.branch = "gh-pages"
end

activate :directory_indexes
activate :relative_assets
