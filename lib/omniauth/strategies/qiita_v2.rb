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
          followees_count: raw_info['followees_count'],
          followers_count: raw_info['followers_count'],
          items_count: raw_info['items_count'],
          urls: {
            website: raw_info['website_url'],
            twitter: raw_info['twitter_screen_name'] ? "https://x.com/#{raw_info['twitter_screen_name']}" : nil,
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

      def raw_info # rubocop:disable Metrics/AbcSize
        @raw_info ||= begin
          access_token.get(USER_INFO_URL).parsed || {}
        rescue ::OAuth2::Error => e
          case e.response.status
          when 401
            log :error, '401 Unauthorized - Invalid access token'
            raise ::OmniAuth::NoSessionError.new('Invalid access token')
          when 403
            log :error, '403 Forbidden - Insufficient permissions'
            raise ::OmniAuth::NoSessionError.new('Insufficient permissions')
          when 404
            log :error, '404 Not Found - User not found'
            raise ::OmniAuth::NoSessionError.new('User not found')
          else
            log :error, "API Error: #{e.response.status} - #{e.message}"
            raise e
          end
        rescue ::Errno::ETIMEDOUT
          log :error, 'Connection timed out'
          raise ::OmniAuth::NoSessionError.new('Connection timed out')
        rescue ::SocketError => e
          log :error, "Network error: #{e.message}"
          raise ::OmniAuth::NoSessionError.new('Network error')
        end
      end

      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end

      def authorize_params
        super.tap do |params|
          ['scope', 'state'].each do |v|
            params[v.to_sym] = request.params[v] if request.params[v]
          end
          params[:scope] ||= DEFAULT_SCOPE
          session['omniauth.state'] = params[:state] if params[:state]
        end
      end

      private

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def build_access_token
        verifier = request.params['code']
        token_params = {
          redirect_uri: callback_url,
          client_id: options.client_id,
          client_secret: options.client_secret
        }.merge(token_params_from_options)
        client.auth_code.get_token(verifier, token_params, deep_symbolize(options.auth_token_params))
      rescue ::OAuth2::Error => e
        log :error, "Failed to build access token: #{e.message}"
        fail!(:invalid_credentials, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        log :error, "Timeout during token exchange: #{e.message}"
        fail!(:timeout, e)
      end

      def token_params_from_options
        return {} unless options.token_params

        if options.token_params.is_a?(Hash)
          params = options.token_params
        else
          params = options.token_params.to_hash
        end
        params.transform_keys(&:to_sym)
      end
    end
  end
end
