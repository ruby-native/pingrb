# pingrb

A tiny push notification app to stay on top of your indie business.

Pingrb turns webhook events from the dev tools you actually use (currently
Stripe) into clean, semantic push notifications. Instead of "money moved,"
it tells you "new subscription," "refund issued," "dispute opened."

Live at [pingrb.com](https://pingrb.com).

## How it works

1. Sign up.
2. Add a source.
3. Paste the webhook URL into Stripe's destinations.
4. Get pinged on every event you subscribed to, parsed into a one-liner.

Stripe webhooks are HMAC-verified per source; pingrb stores each source's
signing secret and rejects any unsigned or invalid request.

## Stack

- Rails 8.1 on Ruby 4.0
- SQLite (multi-database: primary, cache, queue, cable)
- Solid Queue / Solid Cache / Solid Cable
- Hotwire (Turbo + Stimulus) with morph-refresh broadcasts
- Tailwind CSS v4 (IBM Plex Mono throughout)
- Postmark for mail

## Local development

```bash
bin/setup        # bundle install + db setup + seed
bin/dev          # Tailwind watcher + Rails server on :3010
bin/rails test   # 50+ tests
```

The dev seed creates a `user@example.com` / `password` account with two
sources and a few notifications. The sign-in form auto-fills these in
development.

For real webhook testing, use a Cloudflare quick tunnel:

```bash
cloudflared tunnel --url http://localhost:3010
echo "https://your-tunnel.trycloudflare.com" > tmp/public_host
```

The `public_webhook_url` helper reads `tmp/public_host` so the source
show page displays the public URL to paste into Stripe.

## Adding a new source

1. Add the parser type to `Source::PARSER_TYPES` in `app/models/source.rb`.
2. Create a parser at `app/parsers/<name>_parser.rb` inheriting from `Parser`.
3. Add setup + test partials at `app/views/sources/_setup_<name>.html.erb`
   and `_test_<name>.html.erb`.
4. Wire signature verification in `WebhooksController#verify_signature`
   if the source signs requests.
5. Tests at `test/parsers/<name>_parser_test.rb`.

## Deploy

Hatchbox-managed. Production config in `config/environments/production.rb`
assumes SSL termination upstream, restricts hosts to `pingrb.com`, and
uses Postmark for mail (token in encrypted credentials).

## License

Private.
