# Be sure to restart your server when you modify this file.

# Handles Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible.
# See: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization']
  end
end
