# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class QiitaV2 < OmniAuth::Strategies::OAuth2
      DEFAULT_SCOPE = 'read_qiita'
      USER_INFO_URL = '/api/v2/authenticated_user'

      option :name, 'qiita_v2'
      option :client_options, {
        site: 'https://qiita.com',
        authorize_url: '/api/v2/oauth/authorize',
        token_url: '/api/v2/access_tokens'
      }
      option :token_params, { parse: :json }
      option :authorize_options, [:scope, :state]
      option :scope, DEFAULT_SCOPE

      uid { raw_info['id'] }

      info do
        prune!({
          name: raw_info['name'],
          nickname: raw_info['id'],
          email: nil, # Qiita API v2 does not provide email
          description: raw_info['description'],
          image: raw_info['profile_image_url'],
          location: raw_info['location'],
          urls: {
            website: raw_info['website_url'],
            x: raw_info['twitter_screen_name'] ? "https://x.com/#{raw_info['twitter_screen_name']}" : nil,
            twitter: raw_info['twitter_screen_name'] ? "https://twitter.com/#{raw_info['twitter_screen_name']}" : nil,
            facebook: raw_info['facebook_id'] ? "https://facebook.com/#{raw_info['facebook_id']}" : nil,
            linkedin: raw_info['linkedin_id'] ? "https://www.linkedin.com/in/#{raw_info['linkedin_id']}" : nil,
            github: raw_info['github_login_name'] ? "https://github.com/#{raw_info['github_login_name']}" : nil
          }.compact
        })
      end

      extra do
        hash = {}
        hash[:raw_info] = raw_info unless skip_info?
        prune!(hash)
      end

      credentials do
        hash = { token: access_token.token }
        hash[:expires] = access_token.expires?
        hash[:expires_at] = access_token.expires_at if access_token.expires?
        hash[:refresh_token] = access_token.refresh_token if access_token.refresh_token
        hash
      end

      def raw_info
        @raw_info ||= access_token.get(USER_INFO_URL).parsed
      end

      def callback_url
        options[:redirect_uri] || (full_host + callback_path)
      end

      def authorize_params
        super.tap do |params|
          options[:authorize_options].each do |key|
            params[key] = request.params[key.to_s] unless empty?(request.params[key.to_s])
          end
          params[:scope] ||= DEFAULT_SCOPE
          session['omniauth.state'] = params[:state] unless empty?(params[:state])
        end
      end

      protected

      def build_access_token
        client.get_token(base_params.merge(token_params.to_hash(symbolize_keys: true)).merge(deep_symbolize(options.auth_token_params)))
      end

      private

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          empty?(value)
        end
      end

      def empty?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end

      def base_params
        {
          headers: {
            'Content-Type' => 'application/json'
          },
          client_id: options.client_id,
          client_secret: options.client_secret,
          redirect_uri: callback_url,
          code: request.params['code']
        }
      end
    end
  end
end
