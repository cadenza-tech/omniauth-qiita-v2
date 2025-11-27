# OmniauthQiitaV2

[![License](https://img.shields.io/github/license/cadenza-tech/omniauth-qiita-v2?label=License&labelColor=343B42&color=blue)](https://github.com/cadenza-tech/omniauth-qiita-v2/blob/main/LICENSE.txt) [![Tag](https://img.shields.io/github/tag/cadenza-tech/omniauth-qiita-v2?label=Tag&logo=github&labelColor=343B42&color=2EBC4F)](https://github.com/cadenza-tech/omniauth-qiita-v2/blob/main/CHANGELOG.md) [![Release](https://github.com/cadenza-tech/omniauth-qiita-v2/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/omniauth-qiita-v2/actions?query=workflow%3Arelease) [![Test](https://github.com/cadenza-tech/omniauth-qiita-v2/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/omniauth-qiita-v2/actions?query=workflow%3Atest) [![Lint](https://github.com/cadenza-tech/omniauth-qiita-v2/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/omniauth-qiita-v2/actions?query=workflow%3Alint)

Qiita strategy for OmniAuth.

- [Installation](#installation)
- [Usage](#usage)
  - [Rails Configuration with Devise](#rails-configuration-with-devise)
  - [Configuration Options](#configuration-options)
  - [Auth Hash](#auth-hash)
- [Changelog](#changelog)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)
- [Sponsor](#sponsor)

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add omniauth-qiita-v2
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install omniauth-qiita-v2
```

## Usage

### Rails Configuration with Devise

Add the following to `config/initializers/devise.rb`:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.omniauth :qiita, ENV['QIITA_CLIENT_ID'], ENV['QIITA_CLIENT_SECRET']
end
```

Add the OmniAuth callbacks routes to `config/routes.rb`:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
end
```

Add the OmniAuth configuration to your Devise model:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:qiita]
end
```

### Configuration Options

You can configure several options:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.omniauth :qiita, ENV['QIITA_CLIENT_ID'], ENV['QIITA_CLIENT_SECRET'],
    {
      scope: 'read_qiita write_qiita', # Specify OAuth scopes
      callback_path: '/custom/qiita/callback' # Custom callback path
    }
end
```

Available scopes:

- `read_qiita` - Access to read data from Qiita
- `write_qiita` - Access to write data to Qiita

### Auth Hash

After successful authentication, the auth hash will be available in `request.env['omniauth.auth']`:

```ruby
{
  provider: 'qiita',
  uid: 'qiita',
  info: {
    name: 'Qiita キータ',
    nickname: 'qiita',
    image: 'https://s3-ap-northeast-1.amazonaws.com/qiita-image-store/0/88/ccf90b557a406157dbb9d2d7e543dae384dbb561/large.png?1575443439',
    description: 'Hello, world.',
    location: 'Tokyo, Japan',
    urls: {
      website: 'https://qiita.com',
      x: 'https://x.com/qiita',
      twitter: 'https://twitter.com/qiita',
      facebook: 'https://facebook.com/qiita',
      linkedin: 'https://www.linkedin.com/in/qiita',
      github: 'https://github.com/qiitan'
    }
  },
  credentials: {
    token: 'access_token_here',
    expires: false
  },
  extra: {
    raw_info: {
      'description' => 'Hello, world.',
      'facebook_id' => 'qiita',
      'followees_count' => 100,
      'followers_count' => 200,
      'github_login_name' => 'qiitan',
      'id' => 'qiita',
      'items_count' => 300,
      'linkedin_id' => 'qiita',
      'location' => 'Tokyo, Japan',
      'name' => 'Qiita キータ',
      'organization' => 'Qiita Inc.',
      'permanent_id' => 1,
      'profile_image_url' => 'https://s3-ap-northeast-1.amazonaws.com/qiita-image-store/0/88/ccf90b557a406157dbb9d2d7e543dae384dbb561/large.png?1575443439',
      'team_only' => false,
      'twitter_screen_name' => 'qiita',
      'website_url' => 'https://qiita.com',
      'image_monthly_upload_limit' => 1048576,
      'image_monthly_upload_remaining' => 524288
    }
  }
}
```

## Changelog

See [CHANGELOG.md](https://github.com/cadenza-tech/omniauth-qiita-v2/blob/main/CHANGELOG.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cadenza-tech/omniauth-qiita-v2. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cadenza-tech/omniauth-qiita-v2/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/cadenza-tech/omniauth-qiita-v2/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the OmniauthQiitaV2 project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cadenza-tech/omniauth-qiita-v2/blob/main/CODE_OF_CONDUCT.md).

## Sponsor

You can sponsor this project on [Patreon](https://patreon.com/CadenzaTech).
