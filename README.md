# Upperkut

[![CircleCI](https://circleci.com/gh/ResultadosDigitais/upperkut/tree/master.svg?style=svg&circle-token=693e512de6985be3b3db12279ba6ed508fb5c6f6)](https://circleci.com/gh/ResultadosDigitais/upperkut/tree/master)
[![Maintainability](https://api.codeclimate.com/v1/badges/ece40319b0db03af891d/maintainability)](https://codeclimate.com/repos/5b318a7c6d37b70272008676/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ece40319b0db03af891d/test_coverage)](https://codeclimate.com/repos/5b318a7c6d37b70272008676/test_coverage)

[[Docs]](https://www.rubydoc.info/gems/upperkut/0.7.2/Upperkut)

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

### Example 1 - Buffered Queue:

1) Create a Worker class and the define how to process the batch;
  ```ruby
  class MyWorker
    include Upperkut::Worker

    def perform(batch_items)
      heavy_processing(batch_items)
      process_metrics(batch_items)
    end
  end
  ```

2) Start pushing items;
  ```ruby
  MyWorker.push_items(
    [
      {
        'id' => SecureRandom.uuid,
        'name' => 'Robert C Hall',
        'action' => 'EMAIL_OPENNED'
      }
    ]
  )
  ```

3) Start Upperkut;
  ```bash
  $ bundle exec upperkut --worker MyWorker --concurrency 10
  ```

### Example 2 - Scheduled Queue:

1) Create a Worker class and the define how to process the batch;
  ```ruby
  require 'upperkut/strategies/scheduled_queue'
  class MyWorker
    include Upperkut::Worker

    setup_upperkut do |config|
      config.strategy = Upperkut::Strategies::ScheduledQueue.new(self)
    end

    def perform(batch_items)
      heavy_processing(batch_items)
      process_metrics(batch_items)
    end
  end
  ```

2) Start pushing items with `timestamp` parameter;
  ```ruby
  # timestamp is 'Thu, 10 May 2019 23:43:58 GMT'
  MyWorker.push_items(
    [
      {
        'timestamp' => '1557531838',
        'id' => SecureRandom.uuid,
        'name' => 'Robert C Hall',
        'action' => 'SEND_NOTIFICATION'
      }
    ]
  )
  ```

3) Start Upperkut;
  ```bash
  $ bundle exec upperkut --worker MyWorker --concurrency 10
  ```

### Example 3 - Priority Queue:

Note: priority queues requires redis 5.0.0+ as it uses ZPOP* commands.

1) Create a Worker class and the define how to process the batch;
  ```ruby
  require 'upperkut/strategies/priority_queue'

  class MyWorker
    include Upperkut::Worker

    setup_upperkut do |config|
      config.strategy = Upperkut::Strategies::PriorityQueue.new(
        self,
        priority_key: -> { |item| item['tenant_id'] }
      )
    end

    def perform(items)
      items.each do |item|
        puts "event dispatched: #{item.inspect}"
      end
    end
  end
  ```

2) So you can enqueue items from different tenants;
  ```ruby
  MyWorker.push_items(
    [
      { 'tenant_id' => 1, 'id' => 1 },
      { 'tenant_id' => 1, 'id' => 2 },
      { 'tenant_id' => 1, 'id' => 3 },
      { 'tenant_id' => 2, 'id' => 4 },
      { 'tenant_id' => 3, 'id' => 5 },
    ]
  )
  ```

  The code above will enqueue items as follows `1, 4, 5, 2, 3`

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
