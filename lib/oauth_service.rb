require "oauth_service/provider"
require "oauth_service/engine"
require "securerandom"
require "rails"

module OauthService
  # The relative route where auth service callback is redirected.
  # Defaults to "/oauth/".
  mattr_accessor :redirect_uri
  @@redirect_uri = "/oauth/"

  # Format of page after login/logout
  # Defaults to "json"
  mattr_accessor :request_format
  @@request_format = "json"

  # Oauth providers to use for Authorization
  # Default to ['YANDEX', 'GOOGLE']
  mattr_accessor :available_providers
  @@available_providers = ['YANDEX', 'GOOGLE']


  # Keys used by Oauth service
  # Write in this format:
  # {
  #   :provider_name_downcased => {
  #     :auth_url => ...,
  #     :client_id => ...,
  #     :client_secret => ...,
  #     :info_url => ...,
  #     :scopes => ...,
  #     :token_url => ...
  #   }
  # }
  # Defaults to {}
  mattr_accessor :providers_keys
  @@providers_keys = {}
          

  # Default way to set up OauthService. Run rails generate oauth_service:install to create
  # a fresh initializer with all configuration values.
  def self.setup
    yield self
  end
end
