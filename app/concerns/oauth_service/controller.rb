require 'active_support/concern'

module OauthService
  module Controller
    extend ActiveSupport::Concern

    def callback
      provider = OauthService::Providers.by_name(params[:provider_name])
      user_info = provider.get_user_info(request.base_url, params[:code]).symbolize_keys

      if user_info[:error].nil?
        @user = OauthService.user_model.find_by_email(user_info[:email])
        if @user
          session[:user_name] = user_info[:name]
          session[:user_email] = user_info[:email]
          session[:access_token] = generate_api_code

          @user.update(
            :access_token => session[:access_token],
            :access_token_expires => Date.today + OauthService.token_expire
          )
        else
          user_info = nil
          user_info = {:error => 'invalid_request'}
        end
      end

      after_callback user_info
      redirect user_info
    end

    def logout
      OauthService.user_model.find_by_email(session[:user_name]).try(:update,
        {
          :access_token => nil,
          :access_token_expires => nil
        }
      )

      session.clear
      redirect_to params[:redirect_uri] || OauthService.redirect_uri
    end

    def login
      @base_url = request.base_url
      session.clear
      session[:redirect_uri] = params[:redirect_uri] || OauthService.redirect_uri

      render :template => 'oauth/login'
    end

    def info
      info = process_access_token params[:access_token]

      respond_to do |format|
        format.any(:json, :xml, :html) { render request.format.to_sym => info[:data], :status => info[:status] }
      end
    end

    protected
      def generate_api_code
        uuid = SecureRandom.uuid
        OauthService.user_model.find_by_access_token(uuid).nil? ? uuid : generate_api_code
      end

      def process_access_token access_token
        message = {
          :data => {},
          :status => 200
        }
        if access_token
          user = OauthService.user_model.find_by_access_token(access_token)
          if user
            if user.access_token_expires > Time.now
              message[:data] =  {
                :user_name => user.name,
                :user_email => user.email
              }
            else
              message[:data] =  {
                :error => 'Expired Access Token',
                :code => 'invalid_token'
              }
              message[:status] = 401
            end
          else
            message[:data] =  {
              :error => 'Invalid Access Token',
              :code => 'invalid_token'
            }
            message[:status] = 401
          end
        else
          message[:data] = {
            :error => 'Access Token not sent',
            :code => 'invalid_request'
          }
          message[:status] = 400
        end
        message
      end

      def redirect user_info
        uri_params = user_info[:error].nil? ? {access_token: @user.access_token} : {error: user_info[:error]}
        redirect_uri = URI.parse(session[:redirect_uri])
        redirect_uri.query = URI.encode_www_form(uri_params)
        session[:redirect_uri] = nil

        redirect_to redirect_uri.to_s
      end

      def after_callback user_info
      end

  end
end
