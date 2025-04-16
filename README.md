# ReactiveActions

ReactiveActions is a Rails gem that provides a framework for handling reactive actions in your Rails application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reactive-actions'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install reactive-actions
```

After installing the gem, run the generator to set up the necessary routes:

```bash
$ rails generate reactive_actions:install
```

## Usage

Once installed, you can access the reactive actions by sending requests to:

```
GET/POST/PUT/PATCH/DELETE /reactive_actions/execute
```

You can pass parameters:
- `action_name`: The name of the action to execute
- `action_params`: Parameters for the action

Example:
```ruby
# Using Rails
response = Net::HTTP.post(
  URI.parse("http://localhost:3000/reactive_actions/execute"),
  { action_name: "update_user", action_params: { id: 1, name: "New Name" } }.to_json,
  "Content-Type" => "application/json"
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Testing

The gem includes a dummy Rails application for testing purposes. To run the tests:

```bash
$ bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/reactive-actions.

## License

The gem is available as open source under the terms of the MIT License.

