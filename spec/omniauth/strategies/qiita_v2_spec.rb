# frozen_string_literal: true

RSpec.describe OmniAuth::Strategies::QiitaV2 do # rubocop:disable RSpec/SpecFilePathFormat
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.new do
      use OmniAuth::Test::PhonySession
      use OmniAuth::Builder do
        provider :qiita_v2, 'client_id', 'client_secret'
      end
      run ->(env) { [404, { 'Content-Type' => 'text/plain' }, [env.key?('omniauth.auth').to_s]] }
    end.to_app
  end
  let(:options) { {} }
  let(:strategy) { described_class.new('app', 'client_id', 'client_secret', options) }

  describe 'default options' do
    it 'has correct name' do
      expect(strategy.options.name).to eq('qiita_v2')
    end

    it 'has correct default scope' do
      expect(strategy.options.scope).to eq('read_qiita')
    end
  end

  describe 'client options' do
    subject(:client_options) { strategy.options.client_options }

    it 'has correct site' do
      expect(client_options.site).to eq('https://qiita.com')
    end

    it 'has correct authorize url' do
      expect(client_options.authorize_url).to eq('/api/v2/oauth/authorize')
    end

    it 'has correct token url' do
      expect(client_options.token_url).to eq('/api/v2/access_tokens')
    end
  end

  describe 'custom options' do
    context 'with custom scope' do
      let(:options) { { scope: 'read_qiita write_qiita' } }

      it 'uses custom scope' do
        expect(strategy.options.scope).to eq('read_qiita write_qiita')
      end
    end

    context 'with custom redirect uri' do
      let(:options) { { redirect_uri: 'https://example.com/auth/callback' } }

      it 'uses custom redirect uri in callback_url' do
        expect(strategy.callback_url).to eq('https://example.com/auth/callback')
      end
    end

    context 'with skip_info option' do
      let(:options) { { skip_info: true } }

      it 'does not include raw_info in extra' do
        allow(strategy).to receive_messages(raw_info: { 'id' => 'test' }, skip_info?: true)
        expect(strategy.extra).to eq({})
      end
    end
  end

  describe '#uid' do
    let(:raw_info) { { 'id' => 'qiita_user_123' } }

    before { allow(strategy).to receive(:raw_info).and_return(raw_info) }

    it 'returns the id from raw_info' do
      expect(strategy.uid).to eq('qiita_user_123')
    end
  end

  describe '#info' do
    let(:raw_info) do
      {
        'id' => 'qiita_user_123',
        'name' => 'Test User',
        'permanent_id' => 1234567890,
        'profile_image_url' => 'http://example.com/avatar.jpg',
        'description' => 'Test description',
        'location' => 'Tokyo',
        'organization' => 'Test Organization',
        'followees_count' => 50,
        'followers_count' => 100,
        'items_count' => 30,
        'website_url' => 'https://example.com',
        'twitter_screen_name' => 'twitter123',
        'facebook_id' => 'facebook123',
        'linkedin_id' => 'linkedin123',
        'github_login_name' => 'github123'
      }
    end

    before { allow(strategy).to receive(:raw_info).and_return(raw_info) }

    it 'returns correct info hash' do
      info = strategy.info
      expect(info).to include(
        name: 'Test User',
        nickname: 'qiita_user_123',
        permanent_id: 1234567890,
        image: 'http://example.com/avatar.jpg',
        description: 'Test description',
        location: 'Tokyo',
        organization: 'Test Organization',
        followees_count: 50,
        followers_count: 100,
        items_count: 30,
        urls: {
          website: 'https://example.com',
          facebook: 'https://facebook.com/facebook123',
          linkedin: 'https://www.linkedin.com/in/linkedin123',
          twitter: 'https://x.com/twitter123',
          github: 'https://github.com/github123'
        }
      )
      expect(info).not_to have_key(:email)
    end

    it 'prunes empty values' do
      allow(strategy).to receive(:raw_info).and_return({ 'id' => 'test', 'name' => '', 'description' => nil })
      info = strategy.info
      expect(info).to have_key(:nickname)
      expect(info).not_to have_key(:name)
      expect(info).not_to have_key(:description)
    end

    context 'with statistics counts' do
      it 'includes zero counts' do
        allow(strategy).to receive(:raw_info).and_return({
          'id' => 'test',
          'followees_count' => 0,
          'followers_count' => 0,
          'items_count' => 0
        })
        info = strategy.info
        expect(info[:followees_count]).to eq(0)
        expect(info[:followers_count]).to eq(0)
        expect(info[:items_count]).to eq(0)
      end

      it 'prunes nil counts' do
        allow(strategy).to receive(:raw_info).and_return({
          'id' => 'test',
          'followees_count' => nil,
          'followers_count' => nil,
          'items_count' => nil
        })
        info = strategy.info
        expect(info).not_to have_key(:followees_count)
        expect(info).not_to have_key(:followers_count)
        expect(info).not_to have_key(:items_count)
      end
    end
  end

  describe '#credentials' do
    let(:access_token) do
      instance_double(
        OAuth2::AccessToken,
        token: 'test_token',
        expires?: true,
        expires_at: 1234567890,
        refresh_token: 'refresh_token'
      )
    end

    before { allow(strategy).to receive(:access_token).and_return(access_token) }

    it 'returns credentials hash' do
      credentials = strategy.credentials
      expect(credentials).to include(
        token: 'test_token',
        expires: true,
        expires_at: 1234567890,
        refresh_token: 'refresh_token'
      )
    end

    context 'without refresh token' do
      let(:access_token) do
        instance_double(
          OAuth2::AccessToken,
          token: 'test_token',
          expires?: false,
          refresh_token: nil
        )
      end

      it 'does not include refresh_token' do
        credentials = strategy.credentials
        expect(credentials).to include(
          token: 'test_token',
          expires: false
        )
        expect(credentials).not_to have_key(:expires_at)
        expect(credentials).not_to have_key(:refresh_token)
      end
    end
  end

  describe '#raw_info' do
    let(:access_token) { instance_double(OAuth2::AccessToken) }
    let(:response) { instance_double(OAuth2::Response, parsed: { 'id' => 'test123' }) }

    before { allow(strategy).to receive(:access_token).and_return(access_token) }

    context 'when API request is successful' do
      before { allow(access_token).to receive(:get).with('/api/v2/authenticated_user').and_return(response) }

      it 'fetches user info from API' do
        expect(strategy.raw_info).to eq({ 'id' => 'test123' })
      end

      it 'memoizes the result' do
        2.times { strategy.raw_info }
        expect(access_token).to have_received(:get).once
      end
    end

    context 'when API returns 401 Unauthorized' do
      let(:error_response) { instance_double(OAuth2::Response, status: 401) }
      let(:oauth_error) { OAuth2::Error.new(error_response) }

      before do
        allow(access_token).to receive(:get).with('/api/v2/authenticated_user').and_raise(oauth_error)
        allow(strategy).to receive(:log)
      end

      it 'raises OmniAuth::NoSessionError' do
        expect { strategy.raw_info }.to raise_error(OmniAuth::NoSessionError, 'Invalid access token')
      end

      it 'logs the error' do
        expect { strategy.raw_info }.to raise_error(OmniAuth::NoSessionError)
        expect(strategy).to have_received(:log).with(:error, '401 Unauthorized - Invalid access token')
      end
    end

    context 'when API returns 403 Forbidden' do
      let(:error_response) { instance_double(OAuth2::Response, status: 403) }
      let(:oauth_error) { OAuth2::Error.new(error_response) }

      before do
        allow(access_token).to receive(:get).and_raise(oauth_error)
        allow(strategy).to receive(:log)
      end

      it 'raises OmniAuth::NoSessionError with appropriate message' do
        expect { strategy.raw_info }.to raise_error(OmniAuth::NoSessionError, 'Insufficient permissions')
      end
    end

    context 'when API returns 404 Not Found' do
      let(:error_response) { instance_double(OAuth2::Response, status: 404) }
      let(:oauth_error) { OAuth2::Error.new(error_response) }

      before do
        allow(access_token).to receive(:get).and_raise(oauth_error)
        allow(strategy).to receive(:log)
      end

      it 'raises OmniAuth::NoSessionError with appropriate message' do
        expect { strategy.raw_info }.to raise_error(OmniAuth::NoSessionError, 'User not found')
      end
    end

    context 'when connection times out' do
      before do
        allow(access_token).to receive(:get).and_raise(Errno::ETIMEDOUT)
        allow(strategy).to receive(:log)
      end

      it 'raises OmniAuth::NoSessionError' do
        expect { strategy.raw_info }.to raise_error(OmniAuth::NoSessionError, 'Connection timed out')
      end
    end

    context 'when network error occurs' do
      before do
        allow(access_token).to receive(:get).and_raise(SocketError.new('getaddrinfo: nodename nor servname provided'))
        allow(strategy).to receive(:log)
      end

      it 'raises OmniAuth::NoSessionError' do
        expect { strategy.raw_info }.to raise_error(OmniAuth::NoSessionError, 'Network error')
      end
    end

    context 'when API returns other errors' do
      let(:error_response) { instance_double(OAuth2::Response, status: 500) }
      let(:oauth_error) { OAuth2::Error.new(error_response) }

      before do
        allow(oauth_error).to receive(:message).and_return('Internal Server Error')
        allow(access_token).to receive(:get).with('/api/v2/authenticated_user').and_raise(oauth_error)
        allow(strategy).to receive(:log)
      end

      it 're-raises the original error' do
        expect { strategy.raw_info }.to raise_error(OAuth2::Error)
      end

      it 'logs the error with status and message' do
        expect { strategy.raw_info }.to raise_error(OAuth2::Error)
        expect(strategy).to have_received(:log).with(:error, 'API Error: 500 - Internal Server Error')
      end
    end
  end

  describe '#callback_url' do
    context 'without redirect_uri option' do
      it 'builds callback url from request' do
        allow(strategy).to receive_messages(full_host: 'https://example.com', script_name: '', callback_path: '/auth/qiita_v2/callback')
        expect(strategy.callback_url).to eq('https://example.com/auth/qiita_v2/callback')
      end
    end

    context 'with redirect_uri option' do
      let(:options) { { redirect_uri: 'https://custom.example.com/callback' } }

      it 'uses redirect_uri option' do
        expect(strategy.callback_url).to eq('https://custom.example.com/callback')
      end
    end
  end

  describe '#authorize_params' do
    let(:request) { instance_double(Rack::Request, params: {}) }

    before { allow(strategy).to receive_messages(request: request, session: {}) }

    it 'includes default scope when not specified' do
      params = strategy.authorize_params
      expect(params[:scope]).to eq('read_qiita')
    end

    context 'with scope in request params' do
      let(:request) { instance_double(Rack::Request, params: { 'scope' => 'read_qiita write_qiita' }) }

      it 'uses scope from request params' do
        params = strategy.authorize_params
        expect(params[:scope]).to eq('read_qiita write_qiita')
      end
    end

    context 'with state in request params' do
      let(:request) { instance_double(Rack::Request, params: { 'state' => 'random-state' }) }

      it 'includes state in params and stores in session' do
        params = strategy.authorize_params
        expect(params[:state]).to eq('random-state')
        expect(strategy.session['omniauth.state']).to eq('random-state')
      end
    end
  end

  describe '#prune!' do
    it 'removes nil values from hash' do
      hash = { a: 1, b: nil, c: 'test', d: nil }
      expect(strategy.send(:prune!, hash)).to eq({ a: 1, c: 'test' })
    end

    it 'removes empty string values from hash' do
      hash = { a: 'value', b: '', c: 'another', d: '' }
      expect(strategy.send(:prune!, hash)).to eq({ a: 'value', c: 'another' })
    end

    it 'removes empty array values from hash' do
      hash = { a: [1, 2], b: [], c: ['test'], d: [] }
      expect(strategy.send(:prune!, hash)).to eq({ a: [1, 2], c: ['test'] })
    end

    it 'removes empty hash values from hash' do
      hash = { a: { x: 1 }, b: {}, c: { y: 2 }, d: {} }
      expect(strategy.send(:prune!, hash)).to eq({ a: { x: 1 }, c: { y: 2 } })
    end

    it 'keeps zero values' do
      hash = { a: 0, b: nil, c: '', d: 'value' }
      expect(strategy.send(:prune!, hash)).to eq({ a: 0, d: 'value' })
    end

    it 'keeps false values' do
      hash = { a: false, b: nil, c: true, d: '' }
      expect(strategy.send(:prune!, hash)).to eq({ a: false, c: true })
    end

    it 'handles nested hashes' do
      hash = {
        a: { x: 1, y: nil, z: '' },
        b: {},
        c: { nested: { value: 'test', empty: nil } }
      }
      result = strategy.send(:prune!, hash)
      expect(result).to eq({
        a: { x: 1 },
        c: { nested: { value: 'test' } }
      })
    end

    it 'modifies the original hash' do
      hash = { a: 1, b: nil, c: '' }
      result = strategy.send(:prune!, hash)
      expect(hash.object_id).to eq(result.object_id)
      expect(hash).to eq({ a: 1 })
    end
  end

  describe '#build_access_token' do
    let(:request) { instance_double(Rack::Request, params: { 'code' => 'auth_code' }) }
    let(:client) { instance_double(OAuth2::Client) }
    let(:auth_code) { instance_double(OAuth2::Strategy::AuthCode) }
    let(:access_token) { instance_double(OAuth2::AccessToken) }

    before do
      allow(client).to receive(:auth_code).and_return(auth_code)
      allow(strategy).to receive_messages(
        request: request,
        client: client,
        callback_url: 'https://example.com/callback',
        options: OmniAuth::Strategy::Options.new(
          client_id: 'client_id',
          client_secret: 'secret',
          token_params: {},
          auth_token_params: {}
        )
      )
    end

    context 'when token exchange is successful' do
      before { allow(client).to receive(:get_token).and_return(access_token) }

      it 'returns access token' do
        expect(strategy.send(:build_access_token)).to eq(access_token)
      end

      it 'includes required parameters' do
        strategy.send(:build_access_token)
        expect(client).to have_received(:get_token).with(
          hash_including(
            headers: { 'Content-Type' => 'application/json' },
            redirect_uri: 'https://example.com/callback',
            client_id: 'client_id',
            client_secret: 'secret',
            code: 'auth_code'
          )
        )
      end
    end

    context 'when OAuth2 error occurs' do
      let(:oauth_error) { OAuth2::Error.new(instance_double(OAuth2::Response, status: 400)) }

      before do
        allow(client).to receive(:get_token).and_raise(oauth_error)
        allow(strategy).to receive(:log)
        allow(strategy).to receive(:fail!)
      end

      it 'logs the error and fails with invalid_credentials' do
        strategy.send(:build_access_token)
        expect(strategy).to have_received(:log).with(:error, /Failed to build access token/)
        expect(strategy).to have_received(:fail!).with(:invalid_credentials, oauth_error)
      end
    end

    context 'when timeout occurs' do
      context 'with Timeout::Error' do
        before do
          allow(client).to receive(:get_token).and_raise(Timeout::Error)
          allow(strategy).to receive(:log)
          allow(strategy).to receive(:fail!)
        end

        it 'logs the error and fails with timeout' do
          strategy.send(:build_access_token)
          expect(strategy).to have_received(:log).with(:error, /Timeout during token exchange/)
          expect(strategy).to have_received(:fail!).with(:timeout, instance_of(Timeout::Error))
        end
      end

      context 'with Errno::ETIMEDOUT' do
        before do
          allow(client).to receive(:get_token).and_raise(Errno::ETIMEDOUT)
          allow(strategy).to receive(:log)
          allow(strategy).to receive(:fail!)
        end

        it 'logs the error and fails with timeout' do
          strategy.send(:build_access_token)
          expect(strategy).to have_received(:log).with(:error, /Timeout during token exchange/)
          expect(strategy).to have_received(:fail!).with(:timeout, instance_of(Errno::ETIMEDOUT))
        end
      end
    end
  end
end
