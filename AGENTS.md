# OIDCProvider — Agent Guidance

Rails engine (originally brandnewbox/oidc_provider) that turns a Rails
application into an OpenID Connect provider, built on the `openid_connect`
gem. It is consumed through git branches, not released gems: consuming
applications pin a cumulative patch branch in their Gemfile (for example
`master+patch-4+5+6+7+8+9`).

## Non-negotiable rules

- Never run `git add`, `git commit`, or `git push` unless explicitly asked.
  The owner reviews and manages version control; branch and merge work is
  done only on request.
- Never force-push, rewrite, or delete published branches. Cumulative
  branches are pinned by name in consumers' Gemfiles — they are public API.
- Do not mention consuming applications, their companies, or their
  infrastructure by name anywhere in this repository (code, comments,
  commit messages, or docs). Refer to them generically as "the consuming
  application".
- Keep every change retro-compatible with the supported Rails versions
  (`rails (> 4.0)` in the gemspec). When an API differs across Rails
  versions, either find a form that works everywhere, or branch on the
  running Rails version. The established idiom is in
  `app/models/oidc_provider/authorization.rb`: the `serialize` coder is
  passed as `coder: JSON` on Rails 7.1+ and positionally on older Rails,
  selected with
  `Gem::Version.new(ActiveSupport::VERSION::STRING) >= Gem::Version.new('7.1')`.
- Never expose secrets. The OIDC signing key lives in the consuming
  application (`lib/oidc_provider_key.pem`, path overridable through
  `OIDC_PROVIDER_PRIVATE_KEY_PATH`, passphrase through
  `OIDC_PROVIDER_KEY_PASSPHRASE`) — not in this repository.

## Branch and patch model

- `master` is the base line. Do not put consumer-specific work on it.
- Each patch lives on its own branch `patch-N`, created from `master`,
  ideally as one focused commit.
- Cumulative branches named `master+patch-4+5+6+7+8(+…+N)` merge the patch
  branches in order; consumers pin these by branch name.
- To add a patch:
  1. `git checkout -b patch-N master` and make the change there.
  2. Create the next cumulative branch from the latest one:
     `git checkout -b master+patch-4+5+6+7+8+N master+patch-4+5+6+7+8`.
  3. `git merge --no-ff patch-N`. Expect conflicts where earlier patches
     touched the same files (typically
     `app/models/oidc_provider/authorization.rb`); resolve by keeping both
     sides' changes. Commit message convention:
     `Merge branch 'patch-N' into master+patch-4+5+6+7+8+N`.
  4. Never update an existing cumulative branch: its name must keep
     describing its content, and older branches stay pinned by other
     applications.
- Patch branches are based on `master`, so their file set and gemspec can
  differ from the cumulative branches (earlier patches added files such as
  `lib/oidc_provider/scope_config.rb` and `response_object_builder.rb`, and
  patch-5 modernized the gemspec from `openid_connect ~> 1.1.3` to
  `~> 2.2.0`). Dependency resolution always uses the branch the consumer
  pins, not `master`.
- The gem version (`lib/oidc_provider/version.rb`) is bumped on `master`
  only; patch branches do not bump it.

## Repository map

- `app/controllers/oidc_provider/` — authorization, discovery, session and
  UserInfo endpoints, plus `concerns/connect_endpoint.rb`.
  `authorizations_controller.rb` passes `allow_other_host: true` (ignored
  before Rails 7) because authorization codes are returned by redirecting
  to the client's registered redirect URI, which is intentionally on
  another host.
- `app/models/oidc_provider/` — `Authorization` (scopes and claims
  serialized as JSON; claims-request support exists on cumulative
  branches), `AccessToken`, `IdToken` (RSA signing, key pair loaded lazily
  from the host application).
- `lib/oidc_provider/` — engine definition, scope definitions, token
  endpoint, client store, response-object builders.
- `lib/generators/oidc_provider/` — install generator: installs the
  initializer and injects the default routes into the host application's
  routes file.
- `test/dummy/` — dummy Rails application backing the engine's minitest
  suite.

## Verification

- The gem's own suite is thin (`test/**/*_test.rb` through the dummy app)
  and runs on the host; this repository has no Docker setup of its own:

  ```sh
  bundle install && bundle exec rake test
  ```

- Real verification happens in a consuming application. When the consumer
  runs its Rails stack under Docker Compose with an `app` service and
  mounts this checkout inside it (for example at `/gems/oidc_provider`),
  develop and test without pushing using bundler's local override (the
  checkout must sit on the branch the consumer's Gemfile pins):

  ```sh
  docker compose run --rm --no-deps \
    -e BUNDLE_LOCAL__OIDC_PROVIDER=/gems/oidc_provider \
    app bundle install
  docker compose run --rm --no-deps \
    -e BUNDLE_LOCAL__OIDC_PROVIDER=/gems/oidc_provider \
    app bundle exec rails runner 'puts OIDCProvider::Authorization'
  ```

  Bundler maps the `local.oidc_provider` config key to the
  `BUNDLE_LOCAL__OIDC_PROVIDER` environment variable (periods become double
  underscores; underscores in the gem name stay single).
- Consumers' CI resolves the pinned branch from GitHub, so branches must be
  pushed before their pipelines can pass. Their `Gemfile.lock` records both
  the branch and the exact revision.

## Commit style

- Imperative subject line (`Fixes…`, `Allows…`, `Makes…`); the body explains
  the motivation and the Rails-version compatibility implications.
