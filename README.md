# Upperkut

Batch background processing tool.

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
                                                                                                        
    setup_upperkut do |s|
      # Define which redis instance you want to use
      s.redis = Redis.new(url: ENV['ANOTHER_REDIS_INSTANCE_URL'])
                                                                                                        
      # Define the amount of items must be accumulated
      s.batch_size = 2_000 # The default value is 1_000
                                                                                                        
      # How frequent the Processor should hit redis looking for elegible
      # batch. The default value is 5. You can also set the env
      # UPPERKUT_POLLING_INTERVAL.
      s.polling_interval = 4
                                                                                                        
      # How long the Processor should wait to process batch even though
      # the amount of items did not reached the batch_size.
      s.max_wait = 300
    end
                                                                                                        
    def perform(batch_items)
      SidekiqJobA.perform_async(batch_items)
      SidekiqJobB.perform_async(batch_items)
                                                                                                        
      process_metrics(batch_items)
    end
  end
  ```
                                                                                                        
2) Start pushings items;
  ```ruby                                                                                                
  Myworker.push([{'id' => SecureRandom.uuid}, 'name' => 'Robert C Hall',  'action' => 'EMAIL_OPENNED'])
  ```
                                                                                                        
3) Start Upperkut;
  ```bash
  $ bundle exec upperkut --worker MyWorker --concurrency 10
  ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/upperkut. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Upperkut project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/upperkut/blob/master/CODE_OF_CONDUCT.md).
