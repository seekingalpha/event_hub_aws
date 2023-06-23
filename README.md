# EventHubAws

AWS adapter for the [event_hub](https://github.com/seekingalpha/event_hub) gem.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add event_hub_aws

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install event_hub_aws

## Usage

You can read the the general idea of the `event_hub` gem [here](https://github.com/seekingalpha/event_hub).
The AWS adapter has its specific config:

```yaml
# config/event_hub.yml
development:
  credentials:
    region: us-west-2
    access_key_id: 123
    secret_access_key: 321
  adapter: Aws
  queue_url: https://sqs.us-west-2.amazonaws.com/1234567890/events.fifo
  queue_arn: arn:aws:sqs:us-west-2:1234567890:events.fifo
  exchange_arn: arn:aws:sns:us-west-2:1234567890:event-hub.fifo
  subscribe:
    user_registered:
      handler: Handlers::UserRegistered
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/event_hub_aws. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/event_hub_aws/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the EventHubAws project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/event_hub_aws/blob/master/CODE_OF_CONDUCT.md).
