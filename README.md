# OIDCProvider
A Rails engine for providing OpenID Connect authorization. Uses the openid_connect gem to turn a Rails app into an OpenID Connect provider.

## Usage
Use your application as an Open ID provider.

You'll need some kind of user authentication to exist on you application first. Normally we use Devise.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'oidc_provider'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install oidc_provider
```

Install the support stuffs:

* an initializer
* default routes to your routes file

```bash
$ rails generate oidc_provider:install
```

Migrations next:

```bash
$ rails oidc_provider:install:migrations
$ rails db:migrate
```

### Private Key

This gem signs the generated [JWT (JSON Web Tokens)](https://jwt.io/) using a
private key that should exist at the path `lib/oidc_provider_key.pem` in your
Rails application.

You can pass its passphrase using the `OIDC_PROVIDER_KEY_PASSPHRASE` environment
variable.

This gem provide a convenient way of generating one if you need it by running :

```bash
$ rails oidc_provider:generate_key
```

# Testing

Visit: https://demo.c2id.com/oidc-client/

Click "Client details"

Copy and paste the client ID, secret, and redirection URI into your `config/initializers/oidc_provider.rb` config for a new client.

# Testing Provider Details

Visit: https://demo.c2id.com/oidc-client/

Click "OpenID provider details"

Put in your website as the issuer and click "Query"

You should see values generated for all 4 endpoints below.

# Testing Access

Visit: https://demo.c2id.com/oidc-client/

Click "Authenticate end-user"

Click "Log in with OpenID Connect". You should see the following headings:

* OpenID authentication response
* Token response
* Provider public RSA JSON Web Key (JWK)
* ID token
* UserInfo (with your email in there)


## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## How to build this gem

```
gem build oidc_provider.gemspec
gem push oidc_provider-0.3.10.gem
```
