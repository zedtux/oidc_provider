module OIDCProvider
  class Authorization < ApplicationRecord
    belongs_to :account, class_name: OIDCProvider.account_class
    has_one :access_token
    has_one :id_token

    scope :valid, -> { where(arel_table[:expires_at].gteq(Time.now.utc)) }

    attribute :code, :string, default: -> { SecureRandom.hex 32 }
    attribute :expires_at, :datetime, default: -> { 5.minutes.from_now }

    # Rails 7.1 introduced the `coder:` keyword argument for `serialize`, and
    # Rails 7.2 removed the positional coder argument (its signature is now
    # `serialize(attr_name, coder: nil, type: Object, yaml: {}, **options)`).
    # The coder is therefore passed as a keyword argument on Rails 7.1+ and
    # positionally on older versions, keeping the same behaviour everywhere.
    if Gem::Version.new(ActiveSupport::VERSION::STRING) >= Gem::Version.new('7.1')
      serialize :scopes, coder: JSON
    else
      serialize :scopes, JSON
    end

    def expire!
      self.expires_at = Time.now
      self.save!
    end

    def access_token
      super || expire! && generate_access_token!
    end

    def id_token
      super || generate_id_token!
    end

    private

    def generate_access_token!
      token = create_access_token!
      token
    end

    def generate_id_token!
      token = build_id_token
      token.nonce = nonce
      token.save!
      token
    end
  end
end
