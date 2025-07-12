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
  config.omniauth :qiita_v2, ENV['QIITA_CLIENT_ID'], ENV['QIITA_CLIENT_SECRET']
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
         :omniauthable, omniauth_providers: %i[qiita_v2]
end
```

### Configuration Options

You can configure several options:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.omniauth :qiita_v2, ENV['QIITA_CLIENT_ID'], ENV['QIITA_CLIENT_SECRET'],
    {
      scope: 'read_qiita write_qiita', # Specify OAuth scopes
      callback_path: '/custom/qiita_v2/callback' # Custom callback path
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
  provider: 'qiita_v2',
  uid: 'example_qiita_user_john_doe',
  info: {
    name: 'John Doe',
    nickname: 'example_qiita_user_john_doe',
    image: 'https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/...',
    description: 'Software Developer',
    location: 'Tokyo, Japan',
    followees_count: 50,
    followers_count: 100,
    items_count: 30,
    urls: {
      website: 'https://example.com',
      twitter: 'https://x.com/...',
      facebook: 'https://facebook.com/...',
      linkedin: 'https://www.linkedin.com/in/...',
      github: 'https://github.com/...'
    }
  },
  credentials: {
    token: 'access_token_here',
    expires: false
  },
  extra: {
    raw_info: {
      # Complete user information from Qiita API
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
