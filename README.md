# Upperkut

[![CircleCI](https://circleci.com/gh/ResultadosDigitais/upperkut/tree/master.svg?style=svg&circle-token=693e512de6985be3b3db12279ba6ed508fb5c6f6)](https://circleci.com/gh/ResultadosDigitais/upperkut/tree/master)
[![Maintainability](https://api.codeclimate.com/v1/badges/ece40319b0db03af891d/maintainability)](https://codeclimate.com/repos/5b318a7c6d37b70272008676/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ece40319b0db03af891d/test_coverage)](https://codeclimate.com/repos/5b318a7c6d37b70272008676/test_coverage)

Background processing framework for Ruby applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'upperkut'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install upperkut

## Usage
Examples:

1) Create a Worker class and the define how to process the batch;
  ```ruby
  class MyWorker
    include Upperkut::Worker

    # This is optional

    setup_upperkut do |config|
      # Define which redis instance you want to use
      config.strategy = Upperkut::Strategies::BufferedQueue.new(
        self,
        redis: { url: ENV['ANOTHER_REDIS_INSTANCE_URL']) },
        batch_size: 400, # How many events should be dispatched to worker.
        max_wait: 300    # How long Processor wait in seconds to process batch.
                         # even though the amount of items did not reached the
                         # the batch_size.
      )

      # How frequent the Processor should hit redis looking for elegible
      # batch. The default value is 5 seconds. You can also set the env
      # UPPERKUT_POLLING_INTERVAL.
      config.polling_interval = 4
    end

    def perform(batch_items)
      heavy_processing(batch_items)
      process_metrics(batch_items)
    end
  end
  ```

2) Start pushings items;
  ```ruby
  Myworker.push_items([{'id' => SecureRandom.uuid, 'name' => 'Robert C Hall',  'action' => 'EMAIL_OPENNED'}])
  ```

3) Start Upperkut;
  ```bash
  $ bundle exec upperkut --worker MyWorker --concurrency 10
  ```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ResultadosDigitais/upperkut. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Upperkut project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ResultadosDigitais/upperkut/blob/master/CODE_OF_CONDUCT.md).
