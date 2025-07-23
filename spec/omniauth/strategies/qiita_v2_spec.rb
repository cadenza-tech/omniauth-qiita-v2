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
    it 'has correct default values' do
      expect(strategy.options.name).to eq('qiita_v2')
      expect(strategy.options.scope).to eq('read_qiita')
      expect(strategy.options.client_options.site).to eq('https://qiita.com')
      expect(strategy.options.client_options.authorize_url).to eq('/api/v2/oauth/authorize')
      expect(strategy.options.client_options.token_url).to eq('/api/v2/access_tokens')
    end
  end

  describe 'custom options' do
    context 'with custom scope' do
      let(:options) { { scope: 'read_qiita write_qiita' } }

      it 'uses custom scope' do
        expect(strategy.options.scope).to eq('read_qiita write_qiita')
      end
    end
  end

  describe '#uid' do
    let(:raw_info) { { 'id' => 'qiita123' } }

    before { allow(strategy).to receive(:raw_info).and_return(raw_info) }

    it 'returns the id from raw_info' do
      expect(strategy.uid).to eq('qiita123')
    end
  end

  describe '#info' do
    let(:raw_info) do
      {
        'description' => 'Test description',
        'facebook_id' => 'facebook123',
        'followees_count' => 100,
        'followers_count' => 200,
        'github_login_name' => 'github123',
        'id' => 'qiita123',
        'items_count' => 300,
        'linkedin_id' => 'linkedin123',
        'location' => 'Tokyo',
        'name' => 'Test User',
        'organization' => 'Test Organization',
        'permanent_id' => 1234567890,
        'profile_image_url' => 'http://example.com/avatar.jpg',
        'team_only' => false,
        'twitter_screen_name' => 'twitter123',
        'website_url' => 'https://example.com',
        'image_monthly_upload_limit' => 1048576,
        'image_monthly_upload_remaining' => 524288
      }
    end

    before { allow(strategy).to receive(:raw_info).and_return(raw_info) }

    it 'returns correct info hash' do
      info = strategy.info
      expect(info).to eq(
        name: 'Test User',
        nickname: 'qiita123',
        image: 'http://example.com/avatar.jpg',
        description: 'Test description',
        location: 'Tokyo',
        urls: {
          website: 'https://example.com',
          x: 'https://x.com/twitter123',
          twitter: 'https://twitter.com/twitter123',
          facebook: 'https://facebook.com/facebook123',
          linkedin: 'https://www.linkedin.com/in/linkedin123',
          github: 'https://github.com/github123'
        }
      )
      expect(info).not_to have_key(:email)
    end

    it 'prunes empty values' do
      allow(strategy).to receive(:raw_info).and_return({
        'id' => 'qiita123',
        'name' => nil,
        'description' => ''
      })
      info = strategy.info
      expect(info).to have_key(:nickname)
      expect(info).not_to have_key(:name)
      expect(info).not_to have_key(:description)
    end
  end

  describe '#extra' do
    let(:raw_info) do
      {
        'description' => 'Test description',
        'facebook_id' => 'facebook123',
        'followees_count' => 100,
        'followers_count' => 200,
        'github_login_name' => 'github123',
        'id' => 'qiita123',
        'items_count' => 300,
        'linkedin_id' => 'linkedin123',
        'location' => 'Tokyo',
        'name' => 'Test User',
        'organization' => 'Test Organization',
        'permanent_id' => 1234567890,
        'profile_image_url' => 'http://example.com/avatar.jpg',
        'team_only' => false,
        'twitter_screen_name' => 'twitter123',
        'website_url' => 'https://example.com',
        'image_monthly_upload_limit' => 1048576,
        'image_monthly_upload_remaining' => 524288
      }
    end

    before { allow(strategy).to receive(:raw_info).and_return(raw_info) }

    it 'returns correct extra hash' do
      extra = strategy.extra
      expect(extra).to eq(
        raw_info: {
          'description' => 'Test description',
          'facebook_id' => 'facebook123',
          'followees_count' => 100,
          'followers_count' => 200,
          'github_login_name' => 'github123',
          'id' => 'qiita123',
          'items_count' => 300,
          'linkedin_id' => 'linkedin123',
          'location' => 'Tokyo',
          'name' => 'Test User',
          'organization' => 'Test Organization',
          'permanent_id' => 1234567890,
          'profile_image_url' => 'http://example.com/avatar.jpg',
          'team_only' => false,
          'twitter_screen_name' => 'twitter123',
          'website_url' => 'https://example.com',
          'image_monthly_upload_limit' => 1048576,
          'image_monthly_upload_remaining' => 524288
        }
      )
    end

    it 'prunes empty values' do
      allow(strategy).to receive(:raw_info).and_return({
        'id' => 'qiita123',
        'name' => nil,
        'description' => ''
      })
      extra = strategy.extra
      expect(extra[:raw_info]).to have_key('id')
      expect(extra[:raw_info]).not_to have_key('name')
      expect(extra[:raw_info]).not_to have_key('description')
    end

    context 'with statistics counts' do
      it 'includes zero counts' do
        allow(strategy).to receive(:raw_info).and_return({
          'id' => 'qiita123',
          'followees_count' => 0,
          'followers_count' => 0,
          'items_count' => 0
        })
        extra = strategy.extra
        expect(extra[:raw_info]['followees_count']).to eq(0)
        expect(extra[:raw_info]['followers_count']).to eq(0)
        expect(extra[:raw_info]['items_count']).to eq(0)
      end

      it 'prunes nil counts' do
        allow(strategy).to receive(:raw_info).and_return({
          'id' => 'qiita123',
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

    context 'when skip_info is true' do
      let(:options) { { skip_info: true } }

      it 'does not include raw_info in extra' do
        allow(strategy).to receive_messages(raw_info: { 'id' => 'qiita123' }, skip_info?: true)
        expect(strategy.extra).to eq({})
      end
    end
  end

  describe '#credentials' do
    let(:access_token) do
      instance_double(
        OAuth2::AccessToken,
        token: 'token',
        expires?: true,
        expires_at: 1234567890,
        refresh_token: 'refresh_token'
      )
    end

    before { allow(strategy).to receive(:access_token).and_return(access_token) }

    it 'returns credentials hash' do
      credentials = strategy.credentials
      expect(credentials).to include(
        token: 'token',
        expires: true,
        expires_at: 1234567890,
        refresh_token: 'refresh_token'
      )
    end

    context 'when access token does not expire' do
      let(:access_token) do
        instance_double(
          OAuth2::AccessToken,
          token: 'token',
          expires?: false,
          refresh_token: 'refresh_token'
        )
      end

      it 'does not include expires_at' do
        credentials = strategy.credentials
        expect(credentials).to include(
          token: 'token',
          expires: false,
          refresh_token: 'refresh_token'
        )
        expect(credentials).not_to have_key(:expires_at)
      end
    end

    context 'without refresh token' do
      let(:access_token) do
        instance_double(
          OAuth2::AccessToken,
          token: 'token',
          expires?: true,
          expires_at: 1234567890,
          refresh_token: nil
        )
      end

      it 'does not include refresh_token' do
        credentials = strategy.credentials
        expect(credentials).to include(
          token: 'token',
          expires: true,
          expires_at: 1234567890
        )
        expect(credentials).not_to have_key(:refresh_token)
      end
    end
  end

  describe '#raw_info' do
    let(:access_token) { instance_double(OAuth2::AccessToken) }
    let(:response) { instance_double(OAuth2::Response, parsed: { 'id' => 'qiita123' }) }

    before do
      allow(access_token).to receive(:get).and_return(response)
      allow(strategy).to receive(:access_token).and_return(access_token)
    end

    it 'fetches user info from API' do
      expect(strategy.raw_info).to eq({ 'id' => 'qiita123' })
    end

    it 'memoizes the result' do
      2.times { strategy.raw_info }
      expect(access_token).to have_received(:get).once
    end
  end

  describe '#callback_url' do
    context 'without redirect_uri option' do
      it 'builds callback url from request' do
        allow(strategy).to receive_messages(full_host: 'https://example.com', callback_path: '/auth/qiita_v2/callback')
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

  describe '#build_access_token' do
    let(:request) { instance_double(Rack::Request, params: { 'code' => 'auth_code' }) }
    let(:client) { instance_double(OAuth2::Client) }
    let(:auth_code) { instance_double(OAuth2::Strategy::AuthCode) }
    let(:access_token) { instance_double(OAuth2::AccessToken) }

    before do
      allow(client).to receive_messages(
        auth_code: auth_code,
        get_token: access_token
      )
      allow(strategy).to receive_messages(
        request: request,
        client: client,
        callback_url: 'https://example.com/callback',
        options: OmniAuth::Strategy::Options.new(
          client_id: 'client_id',
          client_secret: 'client_secret',
          token_params: {},
          token_options: {},
          auth_token_params: {}
        )
      )
    end

    it 'returns access token' do
      expect(strategy.send(:build_access_token)).to eq(access_token)
    end

    it 'includes required parameters' do
      strategy.send(:build_access_token)
      expect(client).to have_received(:get_token).with(
        hash_including(
          headers: {
            'Content-Type' => 'application/json'
          },
          client_id: 'client_id',
          client_secret: 'client_secret',
          redirect_uri: 'https://example.com/callback',
          code: 'auth_code'
        )
      )
    end
  end

  describe '#prune!' do
    it 'removes nil values from hash' do
      hash = { a: 1, b: nil, c: 'test' }
      expect(strategy.send(:prune!, hash)).to eq({ a: 1, c: 'test' })
    end

    it 'removes empty string values from hash' do
      hash = { a: 'value', b: '', c: 'another' }
      expect(strategy.send(:prune!, hash)).to eq({ a: 'value', c: 'another' })
    end

    it 'removes empty array values from hash' do
      hash = { a: [1, 2], b: [], c: ['test'] }
      expect(strategy.send(:prune!, hash)).to eq({ a: [1, 2], c: ['test'] })
    end

    it 'removes empty hash values from hash' do
      hash = { a: { x: 1 }, b: {}, c: { y: 2 } }
      expect(strategy.send(:prune!, hash)).to eq({ a: { x: 1 }, c: { y: 2 } })
    end

    it 'keeps zero values' do
      hash = { a: 0, b: nil, c: 'value' }
      expect(strategy.send(:prune!, hash)).to eq({ a: 0, c: 'value' })
    end

    it 'keeps false values' do
      hash = { a: false, b: nil, c: true }
      expect(strategy.send(:prune!, hash)).to eq({ a: false, c: true })
    end

    it 'handles nested hashes' do
      hash = { a: { x: 1, y: nil, z: '' }, b: { w: nil, x: '', y: [], z: {} }, c: { nested: { value: 'test', empty: nil } } }
      result = strategy.send(:prune!, hash)
      expect(result).to eq({ a: { x: 1 }, c: { nested: { value: 'test' } } })
    end

    it 'modifies the original hash' do
      hash = { a: 1, b: nil, c: 'test' }
      result = strategy.send(:prune!, hash)
      expect(hash.object_id).to eq(result.object_id)
      expect(hash).to eq({ a: 1, c: 'test' })
    end
  end
end
