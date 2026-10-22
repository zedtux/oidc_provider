# frozen_string_literal: true

module OIDCProvider
  class TokenEndpoint
    attr_accessor :app

    delegate :call, to: :app

    def initialize
      @app = Rack::OAuth2::Server::Token.new do |req, res|
        case req.grant_type
        when :authorization_code
          client = find_valid_client_from(req) || req.invalid_client!

          authorization = Authorization.valid.where(client_id: client.identifier, code: req.code).first || req.invalid_grant!
          res.access_token = authorization.access_token.to_bearer_token
          res.id_token = authorization.id_token.to_jwt if authorization.scopes.include?('openid')
        else
          req.unsupported_grant_type!
        end
      end
    end

    private

    def find_valid_client_from(req)
      client = ClientStore.new.find_by(
        identifier: req.client_id,
        secret: req.client_secret
      )

      return nil unless client

      client.redirect_uri.include?(req.redirect_uri) ? client : nil
    end
  end
end
