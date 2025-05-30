# ReactiveActions

ReactiveActions is a Rails gem that provides a framework for handling reactive actions in your Rails application.

## 🚧 Status

This gem is currently in alpha (0.1.0-alpha.1). The API may change between versions.

## 📦 Installation

Add this line to your application's Gemfile:

```ruby
gem 'reactive-actions', '0.1.0-alpha.1'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
gem install reactive-actions --pre
```

After installing the gem, run the generator to set up the necessary files:

```bash
$ rails generate reactive_actions:install
```

## 🎮 Interactive Installation

The install generator provides an interactive setup experience that is fully compatible with Rails 8's native asset pipeline (Propshaft + Importmap):

### Basic Interactive Installation

```bash
$ rails generate reactive_actions:install
```

This will guide you through the setup process with prompts like:

```
Welcome to ReactiveActions installer!
This will help you set up ReactiveActions in your Rails application.

Create ReactiveActions initializer? (recommended) (y/n) y
✓ Created initializer

Create app/reactive_actions directory? (y/n) y
✓ Created actions directory

Generate example action file? (y/n) y
What should the example action be called? [example] user_login
✓ Created user_login_action.rb

Add ReactiveActions routes to your application? (y/n) y
Mount path for ReactiveActions: [/reactive_actions] /api/actions
✓ Added route mounting ReactiveActions at /api/actions

Add ReactiveActions JavaScript client? (y/n) y
✓ Added JavaScript client to importmap
✓ Added ReactiveActions import to app/javascript/application.js

Configure advanced options? (y/n) n

================================================================
ReactiveActions installation complete!
================================================================
```

### Installation Options

You can also use command line options to skip prompts or customize the installation:

```bash
# Skip specific components
$ rails generate reactive_actions:install --skip-routes --skip-javascript

# Use custom mount path
$ rails generate reactive_actions:install --mount-path=/api/reactive

# Skip example action generation
$ rails generate reactive_actions:install --skip-example

# Quiet installation with defaults
$ rails generate reactive_actions:install --quiet
```

### Available Options

- `--skip-routes` - Skip adding routes to your application
- `--skip-javascript` - Skip adding JavaScript imports and setup
- `--skip-example` - Skip generating the example action file
- `--mount-path=PATH` - Specify custom mount path (default: `/reactive_actions`)
- `--quiet` - Run installation with minimal output and default settings

### What Gets Installed

The generator will:
- ✅ Add the necessary routes to your `config/routes.rb`
- ✅ Create the `app/reactive_actions` directory
- ✅ Generate an example action file (customizable name)
- ✅ Add JavaScript to your `config/importmap.rb` (Rails 8 native)
- ✅ Automatically import ReactiveActions in your `application.js`
- ✅ Create an initializer file with configuration options
- ✅ Optionally configure advanced settings like custom delegated methods

## ⚡ Rails 8 Native JavaScript Integration

ReactiveActions now uses Rails 8's native JavaScript approach with **Importmap + Propshaft**, providing seamless integration without additional build steps.

### Automatic Setup

The installer automatically:
1. **Pins the module** in your `config/importmap.rb`:
   ```ruby
   pin "reactive_actions", to: "reactive_actions.js"
   ```

2. **Imports it globally** in your `app/javascript/application.js`:
   ```javascript
   // Import ReactiveActions to make it globally available
   import "reactive_actions"
   ```

3. **Makes it available everywhere** as `window.ReactiveActions`

### Manual Import (Optional)

You can also import it explicitly in specific files:

```javascript
import ReactiveActions from "reactive_actions"

// Use it locally
ReactiveActions.execute('action_name', { param: 'value' })
```

### Backward Compatibility

The JavaScript client supports both Rails 8 (Importmap) and older setups (Sprockets), automatically detecting and configuring the appropriate approach.

## 🚀 Usage

### HTTP API

Once installed, you can access the reactive actions by sending requests to your configured endpoint:

```
GET/POST/PUT/PATCH/DELETE /reactive_actions/execute
```

Or if you used a custom mount path:

```
GET/POST/PUT/PATCH/DELETE /your-custom-path/execute
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

### Creating Custom Actions

You can create custom actions by inheriting from `ReactiveActions::ReactiveAction`:

```ruby
# app/reactive_actions/update_user_action.rb
class UpdateUserAction < ReactiveActions::ReactiveAction
  def action
    user = User.find(action_params[:id])
    user.update(action_params[:user_attributes])
    
    @result = {
      success: true,
      user: user.as_json
    }
  end

  def response
    render json: {
      success: true,
      data: @result
    }
  end
end
```

### Action Directory Structure

Actions are placed in the `app/reactive_actions` directory structure:

```
app/
├── reactive_actions/
│   ├── simple_action.rb
│   ├── user_actions/
│   │   ├── create_user_action.rb
│   │   ├── update_user_action.rb
│   │   └── delete_user_action.rb
│   └── product_actions/
│       ├── create_product_action.rb
│       └── update_product_action.rb
```

Actions in subdirectories are automatically loaded and namespaced under `ReactiveActions`. For example, a file at `app/reactive_actions/user_actions/create_user_action.rb` becomes accessible as `ReactiveActions::CreateUserAction`.

### Action Naming Convention

Action files should follow the naming convention:
- File name: `snake_case_action.rb` (e.g., `update_user_action.rb`)
- Class name: `CamelCaseAction` (e.g., `UpdateUserAction`)
- HTTP parameter: `snake_case` without the `_action` suffix (e.g., `update_user`)

Examples:
- `create_user_action.rb` → `CreateUserAction` → called with `action_name: "create_user"`
- `fetch_product_action.rb` → `FetchProductAction` → called with `action_name: "fetch_product"`

### Advanced Examples

#### Complex Action with Validation and Error Handling

```ruby
# app/reactive_actions/process_payment_action.rb
class ProcessPaymentAction < ReactiveActions::ReactiveAction
  def action
    # Validate required parameters
    validate_parameters!
    
    # Process the payment
    payment_service = PaymentService.new(
      amount: action_params[:amount],
      currency: action_params[:currency],
      payment_method: action_params[:payment_method]
    )
    
    @result = payment_service.process
    
    # Log the transaction
    PaymentLog.create(
      amount: action_params[:amount],
      status: @result[:status],
      transaction_id: @result[:transaction_id]
    )
  rescue PaymentError => e
    @error = { type: 'payment_failed', message: e.message }
  rescue ValidationError => e
    @error = { type: 'validation_failed', message: e.message }
  end

  def response
    if @error
      render json: { success: false, error: @error }, status: :unprocessable_entity
    else
      render json: { success: true, data: @result }
    end
  end

  private

  def validate_parameters!
    required_params = %i[amount currency payment_method]
    missing_params = required_params.select { |param| action_params[param].blank? }
    
    raise ValidationError, "Missing parameters: #{missing_params.join(', ')}" if missing_params.any?
    raise ValidationError, "Invalid amount" unless action_params[:amount].to_f > 0
  end
end
```

#### Action with Background Job Integration

```ruby
# app/reactive_actions/generate_report_action.rb
class GenerateReportAction < ReactiveActions::ReactiveAction
  def action
    # Queue the report generation job
    job = ReportGenerationJob.perform_later(
      user_id: action_params[:user_id],
      report_type: action_params[:report_type],
      filters: action_params[:filters] || {}
    )
    
    @result = {
      job_id: job.job_id,
      status: 'queued',
      estimated_completion: 5.minutes.from_now
    }
  end

  def response
    render json: {
      success: true,
      message: 'Report generation started',
      data: @result
    }
  end
end
```

## 💻 JavaScript Client

ReactiveActions includes a modern JavaScript client that's automatically available after installation.

### Global Usage (Recommended)

After installation, `ReactiveActions` is globally available:

```javascript
// Basic usage (POST method by default)
ReactiveActions.execute('update_user', { id: 1, name: 'New Name' })
  .then(response => {
    if (response.ok) {
      console.log('Success:', response);
    } else {
      console.error('Error:', response);
    }
  });

// Using specific HTTP methods
ReactiveActions.get('fetch_user', { id: 1 });
ReactiveActions.post('create_user', { name: 'New User' });
ReactiveActions.put('update_user', { id: 1, name: 'Updated Name' });
ReactiveActions.patch('partial_update', { id: 1, status: 'active' });
ReactiveActions.delete('delete_user', { id: 1 });

// With custom options
ReactiveActions.execute('custom_action', { data: 'value' }, {
  method: 'POST',
  contentType: 'application/json'
});
```

### ES Module Import (Advanced)

For more control, you can import it explicitly:

```javascript
import ReactiveActions from "reactive_actions"

// Use it in your module
ReactiveActions.execute('action_name', { param: 'value' })
```

### Client Features

The client automatically:
- ✅ **Handles CSRF tokens** - Automatically includes Rails CSRF protection
- ✅ **Formats requests** - Properly formats GET vs POST/PUT/PATCH/DELETE requests
- ✅ **Parses responses** - Automatically parses JSON responses
- ✅ **Returns promises** - Modern async/await compatible
- ✅ **Error handling** - Provides structured error information
- ✅ **Multiple HTTP methods** - Support for GET, POST, PUT, PATCH, DELETE

## Security

ReactiveActions implements several security measures to protect your application:

### 🔒 **Built-in Security Features**

#### Parameter Sanitization
- **Input validation**: Action names are validated against safe patterns (`/\A[a-zA-Z_][a-zA-Z0-9_]*\z/`)
- **Parameter key sanitization**: Only alphanumeric characters, underscores, and hyphens allowed
- **String length limits**: Prevents memory exhaustion attacks (max 10,000 chars)
- **Dangerous prefix filtering**: Blocks parameters starting with `__`, `eval`, `exec`, `system`, etc.

#### CSRF Protection
- **Automatic CSRF tokens**: JavaScript client automatically includes Rails CSRF tokens
- **Same-origin requests**: Credentials are sent only to same-origin requests
- **Controller integration**: Inherits from `ActionController::Base` with CSRF protection

#### Code Injection Prevention
- **Class name validation**: Action names are sanitized before constant lookup
- **Namespace isolation**: Actions are properly namespaced to prevent conflicts
- **Parameter filtering**: Recursive parameter sanitization for nested structures

### 🛡️ **Security Best Practices**

```ruby
# app/reactive_actions/secure_action.rb
class SecureAction < ReactiveActions::ReactiveAction
  def action
    # Always validate user permissions
    raise ReactiveActions::UnauthorizedError unless current_user&.admin?
    
    # Validate and sanitize inputs
    user_id = action_params[:user_id].to_i
    raise ReactiveActions::InvalidParametersError, "Invalid user ID" if user_id <= 0
    
    # Use strong parameters if integrating with models
    permitted_params = action_params.slice(:name, :email).permit!
    
    @result = User.find(user_id).update(permitted_params)
  end
end
```

### ⚠️ **Security Considerations**

- **Always validate user permissions** in your actions
- **Use Rails strong parameters** when working with model updates
- **Sanitize file uploads** if handling file parameters
- **Implement rate limiting** for public-facing actions
- **Log security events** for audit trails

## Performance

### 🚀 **Performance Characteristics**

ReactiveActions is designed to be lightweight and efficient:

- **Minimal overhead**: Direct controller execution without complex middleware chains
- **No database dependencies**: Core functionality doesn't require database connections
- **Efficient autoloading**: Actions are loaded on-demand using Rails' autoloading
- **Memory efficient**: Parameter sanitization prevents memory exhaustion attacks

### 📊 **Performance Best Practices**

#### Action Design
```ruby
# ✅ Good: Lightweight action with focused responsibility
class QuickUpdateAction < ReactiveActions::ReactiveAction
  def action
    User.where(id: action_params[:id]).update_all(
      last_seen_at: Time.current
    )
  end
end

# ❌ Avoid: Heavy operations that should be background jobs
class SlowReportAction < ReactiveActions::ReactiveAction
  def action
    # This should be a background job instead
    @result = generate_complex_report_synchronously
  end
end
```

#### Use Background Jobs for Heavy Operations
```ruby
# ✅ Better approach for time-consuming operations
class InitiateReportAction < ReactiveActions::ReactiveAction
  def action
    ReportGenerationJob.perform_later(action_params)
    @result = { status: 'queued', job_id: SecureRandom.uuid }
  end
end
```

#### Optimize Database Queries
```ruby
class OptimizedAction < ReactiveActions::ReactiveAction
  def action
    # Use includes to avoid N+1 queries
    @users = User.includes(:profile, :posts)
                 .where(id: action_params[:user_ids])
    
    # Use select to limit returned columns
    @summary = User.select(:id, :name, :created_at)
                   .where(active: true)
  end
end
```

### 📈 **Monitoring and Optimization**

- **Monitor response times**: Actions should typically complete in < 100ms
- **Use Rails logging**: ReactiveActions logs execution details at debug level
- **Profile memory usage**: Large parameter sets can impact memory
- **Consider caching**: Use Rails caching for frequently accessed data

## ⚙️ Configuration

The gem can be configured using an initializer (automatically created by the install generator):

```ruby
# config/initializers/reactive_actions.rb
ReactiveActions.configure do |config|
  # Configure methods to delegate from the controller to action classes
  config.delegated_controller_methods += [:custom_method]

  # Configure instance variables to delegate from the controller to action classes
  config.delegated_instance_variables += [:custom_variable]
end

# Set the logger for ReactiveActions
ReactiveActions.logger = Rails.logger
```

### Advanced Configuration

During installation, you can choose to configure advanced options:

- **Custom Controller Methods**: Add additional controller methods to delegate to action classes
- **Logging Level**: Set a custom logging level for ReactiveActions
- **Instance Variables**: Configure which instance variables to delegate from controllers to actions

### Default Delegated Methods

By default, the following controller methods are available in your actions:
- `render`
- `redirect_to`
- `head`
- `params`
- `session`
- `cookies`
- `flash`
- `request`
- `response`

## ❌ Error Handling

ReactiveActions provides structured error handling with specific error types:

- `ActionNotFoundError`: When the requested action doesn't exist
- `MissingParameterError`: When required parameters are missing
- `InvalidParametersError`: When parameters have invalid types or formats
- `UnauthorizedError`: When the user lacks permission for the action
- `ActionExecutionError`: When an error occurs during action execution

All errors return JSON responses with consistent structure:

```json
{
  "success": false,
  "error": {
    "type": "ActionNotFoundError",
    "message": "Action 'non_existent' not found",
    "code": "NOT_FOUND"
  }
}
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### ❓ **Action Not Found Errors**

**Problem**: Getting `ActionNotFoundError` for existing actions

**Solutions**:
```bash
# 1. Check file naming convention
# File: app/reactive_actions/my_action.rb
# Class: MyAction
# Call with: action_name: "my"

# 2. Restart Rails to reload autoloading
rails restart

# 3. Check for syntax errors in action file
rails console
> MyAction # Should load without errors
```

#### ❓ **JavaScript Client Not Working**

**Problem**: `ReactiveActions is not defined` in browser

**Solutions**:
```javascript
// 1. Check importmap.rb includes the pin
// config/importmap.rb should have:
pin "reactive_actions", to: "reactive_actions.js"

// 2. Check application.js imports it
// app/javascript/application.js should have:
import "reactive_actions"

// 3. Clear browser cache and restart Rails
```

#### ❓ **CSRF Token Errors**

**Problem**: Getting `Can't verify CSRF token authenticity`

**Solutions**:
```erb
<!-- 1. Ensure CSRF meta tags are in your layout -->
<%= csrf_meta_tags %>

<!-- 2. Check that protect_from_forgery is enabled -->
<%# In your ApplicationController %>
protect_from_forgery with: :exception
```

#### ❓ **Parameter Sanitization Issues**

**Problem**: Parameters are being rejected or modified unexpectedly

**Solutions**:
```ruby
# 1. Check parameter key format (alphanumeric, underscore, hyphen only)
# ✅ Good: { user_name: "John", user-id: 123 }
# ❌ Bad: { "__eval": "code", "system()": "bad" }

# 2. Check string length limits (max 10,000 characters)
# 3. Review logs for specific sanitization messages
```

#### ❓ **Performance Issues**

**Problem**: Actions are slow or timing out

**Solutions**:
```ruby
# 1. Move heavy operations to background jobs
class SlowAction < ReactiveActions::ReactiveAction
  def action
    # Instead of this:
    # heavy_operation
    
    # Do this:
    HeavyOperationJob.perform_later(action_params)
    @result = { status: 'queued' }
  end
end

# 2. Optimize database queries
# 3. Add caching where appropriate
# 4. Monitor with Rails logs at debug level
```

### Debug Mode

Enable detailed logging for troubleshooting:

```ruby
# config/initializers/reactive_actions.rb
ReactiveActions.logger.level = :debug

# This will log:
# - Action execution details
# - Parameter sanitization steps
# - Error stack traces
# - Performance metrics
```

## 🚄 Rails 8 Compatibility

This gem is designed specifically for Rails 8 and takes advantage of:

- ✅ **Propshaft** - Modern asset pipeline without compilation
- ✅ **Importmap** - Native ES module support without bundling
- ✅ **Rails 8 conventions** - Follows current Rails best practices
- ✅ **Modern JavaScript** - ES6+ classes and async/await
- ✅ **Backward compatibility** - Still works with Sprockets if needed

## 🗺️ Roadmap & Future Improvements

Planned improvements for ReactiveActions:

* Security hooks - methods that run before actions for authentication and authorization checks
* Rate limiting and throttling capabilities
* Enhanced error handling with more granular error types
* Action composition - ability to build complex workflows from smaller actions
* Improved generators for common action patterns
* Built-in testing utilities and helpers
* Auto-generated API documentation
* And much more

## 🛠️ Development

After checking out the repo, run the following to install dependencies:

```bash
$ bundle install
```

Then, run the tests:

```bash
$ bundle exec rspec
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run:

```bash
$ bundle exec rake install
```

## 🧪 Testing

The gem repository includes a dummy Rails application for development and testing purposes. To run the tests:

```bash
$ bundle exec rspec
```

**Note**: The dummy application is only available in the source repository and is not included in the distributed gem.

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/IstvanMs/reactive-actions.

## 📄 License

The gem is available as open source under the terms of the MIT License.