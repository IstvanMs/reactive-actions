# ReactiveActions

ReactiveActions is a Rails gem that provides a framework for handling reactive actions in your Rails application with Stimulus-style DOM binding support.

## 🚧 Status

This gem is currently in alpha (0.1.0-alpha.3). The API may change between versions.

## 📦 Installation

Add this line to your application's Gemfile:

```ruby
gem 'reactive-actions', '0.1.0-alpha.3'
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

Configure rate limiting? (optional but recommended for production) (y/n) y
Enable rate limiting features? (y/n) y
Enable global controller-level rate limiting? (recommended) (y/n) y
Global rate limit (requests per window): [600] 1000
Global rate limit window: [1.minute] 5.minutes
Configure custom rate limit key generator? (advanced) (y/n) n
✓ Rate limiting configured:
  - Rate limiting: ENABLED
  - Global rate limiting: ENABLED
  - Global limit: 1000 requests per 5.minutes

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

# Enable rate limiting during installation
$ rails generate reactive_actions:install --enable-rate-limiting --enable-global-rate-limiting

# Configure rate limiting with custom limits
$ rails generate reactive_actions:install --enable-rate-limiting --global-rate-limit=1000 --global-rate-limit-window="5.minutes"

# Quiet installation with defaults
$ rails generate reactive_actions:install --quiet
```

### Available Options

**Basic Options:**
- `--skip-routes` - Skip adding routes to your application
- `--skip-javascript` - Skip adding JavaScript imports and setup
- `--skip-example` - Skip generating the example action file
- `--mount-path=PATH` - Specify custom mount path (default: `/reactive_actions`)
- `--quiet` - Run installation with minimal output and default settings

**JavaScript Client Options:**
- `--auto-initialize` - Auto-initialize ReactiveActions on page load (default: true)
- `--enable-dom-binding` - Enable automatic DOM binding (default: true)
- `--enable-mutation-observer` - Enable mutation observer for dynamic content (default: true)
- `--default-http-method=METHOD` - Default HTTP method for actions (default: 'POST')

**Rate Limiting Options:**
- `--enable-rate-limiting` - Enable rate limiting features
- `--enable-global-rate-limiting` - Enable global controller-level rate limiting
- `--global-rate-limit=NUMBER` - Global rate limit (requests per window, default: 600)
- `--global-rate-limit-window=DURATION` - Global rate limit window (default: '1.minute')

### What Gets Installed

The generator will:
- ✅ Add the necessary routes to your `config/routes.rb`
- ✅ Create the `app/reactive_actions` directory
- ✅ Generate an example action file (customizable name)
- ✅ Add JavaScript to your `config/importmap.rb` (Rails 8 native)
- ✅ Automatically import ReactiveActions in your `application.js`
- ✅ Create an initializer file with configuration options
- ✅ Configure rate limiting settings (if enabled)
- ✅ Optionally configure advanced settings like custom delegated methods

## ⚡ Rails 8 Native JavaScript Integration

ReactiveActions uses Rails 8's native JavaScript approach with **Importmap + Propshaft**, providing seamless integration without additional build steps.

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

### DOM Binding (Recommended)

The easiest way to use ReactiveActions is with DOM binding - no JavaScript required:

```html
<!-- Basic button click -->
<button reactive-action="click->update_user" 
        reactive-action-user-id="123">
  Update User
</button>

<!-- Live search input -->
<input reactive-action="input->search_users" 
       reactive-action-live="true"
       placeholder="Search...">

<!-- Form submission -->
<form reactive-action="submit->create_post">
  <input name="title" type="text" required>
  <button type="submit">Create Post</button>
</form>

<!-- RESTful actions with HTTP methods -->
<button reactive-action="click->post#create_user">Create</button>
<button reactive-action="click->put#update_user">Update</button>  
<button reactive-action="click->delete#delete_user">Delete</button>
```

### HTTP API

You can also access reactive actions by sending direct HTTP requests:

```
GET/POST/PUT/PATCH/DELETE /reactive_actions/execute
```

Parameters:
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

### JavaScript Client

For programmatic access, use the JavaScript client:

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
```

## 📝 DOM Binding Reference

### Action Syntax

Use `reactive-action` with the format `event->action_name` or `event->method#action_name`:

```html
<!-- Basic actions (uses default POST method) -->
<button reactive-action="click->update_user">Update User</button>
<input reactive-action="change->search_users" type="text">
<div reactive-action="hover->show_preview">Hover me</div>

<!-- With HTTP methods -->
<button reactive-action="click->put#update_user">Update User (PUT)</button>
<button reactive-action="click->delete#delete_user">Delete User</button>
<button reactive-action="click->get#fetch_user">Fetch User</button>

<!-- Multiple actions -->
<button reactive-action="click->post#save mouseenter->get#preview">
  Save Item
</button>
```

### Passing Data

Use `reactive-action-*` attributes to pass data:

```html
<button reactive-action="click->update_user" 
        reactive-action-user-id="123" 
        reactive-action-name="John Doe">
  Update User
</button>
```

Data attributes are automatically converted from kebab-case to snake_case:
- `reactive-action-user-id="123"` → `{ user_id: "123" }`
- `reactive-action-first-name="John"` → `{ first_name: "John" }`

### Supported Events

- **`click`** - Mouse clicks
- **`hover`** - Mouse hover (mouseenter)
- **`change`** - Input value changes
- **`input`** - Input value changes (live)
- **`submit`** - Form submissions
- **`focus`** - Element receives focus
- **`blur`** - Element loses focus
- **`mouseenter`/`mouseleave`** - Mouse interactions
- **`keyup`/`keydown`** - Keyboard events

### Loading States

Elements automatically get loading states:

```css
.reactive-loading {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Buttons get disabled and show loading text */
button.reactive-loading {
  background-color: #ccc;
}
```

Custom loading text:
```html
<button reactive-action="click->slow_action" 
        data-loading-text="Processing...">
  Start Process
</button>
```

### Success and Error Handling

#### Custom Events
```javascript
// Listen for successful actions
document.addEventListener('reactive-action:success', (event) => {
  const { response, element, originalEvent } = event.detail;
  console.log('Action succeeded:', response);
});

// Listen for action errors
document.addEventListener('reactive-action:error', (event) => {
  const { error, element, originalEvent } = event.detail;
  console.error('Action failed:', error);
});
```

#### Callback Functions
```html
<button reactive-action="click->update_user"
        reactive-action-success="handleSuccess"
        reactive-action-error="handleError">
  Update User
</button>

<script>
function handleSuccess(response, element, event) {
  alert('User updated successfully!');
}

function handleError(error, element, event) {
  alert('Failed to update user: ' + error.message);
}
</script>
```

## ⚙️ Configuration

ReactiveActions provides flexible initialization options:

### Automatic Initialization (Default)

```javascript
// Automatically set up during installation
// Available globally as window.ReactiveActions
ReactiveActions.execute('action_name', { param: 'value' })
```

### Manual Initialization

```javascript
// Import the client class
import ReactiveActionsClient from "reactive_actions"

// Create and configure instance
const reactiveActions = new ReactiveActionsClient({
  baseUrl: '/custom/path/execute',
  enableAutoBinding: true,
  enableMutationObserver: true,
  defaultHttpMethod: 'POST'
});

// Initialize DOM bindings
reactiveActions.initialize();

// Make available globally (optional)
window.ReactiveActions = reactiveActions;
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `baseUrl` | `'/reactive_actions/execute'` | API endpoint for action requests |
| `enableAutoBinding` | `true` | Automatically bind elements on initialization |
| `enableMutationObserver` | `true` | Watch for dynamically added elements |
| `defaultHttpMethod` | `'POST'` | Default HTTP method when not specified |

### Advanced Configuration Examples

```javascript
// Environment-specific configuration
const reactiveActions = new ReactiveActionsClient({
  baseUrl: Rails.env === 'development' ? 
    'http://localhost:3000/reactive_actions/execute' : 
    '/reactive_actions/execute'
});

// For SPAs with manual DOM control
const manualReactiveActions = new ReactiveActionsClient({ 
  enableAutoBinding: false,
  enableMutationObserver: false 
});

// Initialize only when needed
document.addEventListener('turbo:load', () => {
  manualReactiveActions.initialize();
});

// Reconfigure after creation
reactiveActions.configure({
  defaultHttpMethod: 'PUT',
  enableAutoBinding: false
}).reinitialize();

// Get current configuration
console.log(reactiveActions.getConfig());

// Bind specific elements manually
reactiveActions.bindElement(document.getElementById('my-button'));

// Force re-initialization
reactiveActions.reinitialize();
```

## 🎯 Creating Custom Actions

Create custom actions by inheriting from `ReactiveActions::ReactiveAction`:

```ruby
# app/reactive_actions/update_user_action.rb
class UpdateUserAction < ReactiveActions::ReactiveAction
  def action
    user = User.find(action_params[:user_id])
    user.update(name: action_params[:name])
    
    @result = {
      success: true,
      user: user.as_json(only: [:id, :name, :email])
    }
  end

  def response
    render json: @result
  end
end
```

### Action Directory Structure

Actions are placed in the `app/reactive_actions` directory:

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

### Action Naming Convention

- File name: `snake_case_action.rb` (e.g., `update_user_action.rb`)
- Class name: `CamelCaseAction` (e.g., `UpdateUserAction`)
- HTTP parameter: `snake_case` without `_action` suffix (e.g., `update_user`)

### Advanced Action Examples

#### RESTful User Management
```ruby
# app/reactive_actions/create_user_action.rb
class CreateUserAction < ReactiveActions::ReactiveAction
  def action
    user = User.create!(action_params.slice(:name, :email))
    @result = { user: user.as_json, message: 'User created successfully' }
  end

  def response
    render json: @result, status: :created
  end
end

# app/reactive_actions/update_user_action.rb  
class UpdateUserAction < ReactiveActions::ReactiveAction
  def action
    user = User.find(action_params[:user_id])
    user.update!(action_params.slice(:name, :email))
    @result = { user: user.as_json, message: 'User updated successfully' }
  end

  def response
    render json: @result
  end
end

# app/reactive_actions/delete_user_action.rb
class DeleteUserAction < ReactiveActions::ReactiveAction
  def action
    user = User.find(action_params[:user_id])
    user.destroy!
    @result = { message: 'User deleted successfully' }
  end

  def response
    render json: @result
  end
end
```

#### Live Search with Filtering
```ruby
# app/reactive_actions/search_users_action.rb
class SearchUsersAction < ReactiveActions::ReactiveAction
  def action
    query = action_params[:value] || action_params[:query]
    
    users = User.where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
                .limit(10)
                .select(:id, :name, :email)
    
    @result = {
      users: users.as_json,
      count: users.count,
      query: query
    }
  end

  def response
    render json: @result
  end
end
```

#### Background Job Integration
```ruby
# app/reactive_actions/generate_report_action.rb
class GenerateReportAction < ReactiveActions::ReactiveAction
  def action
    job = ReportGenerationJob.perform_later(
      user_id: action_params[:user_id],
      report_type: action_params[:report_type]
    )
    
    @result = {
      job_id: job.job_id,
      status: 'queued',
      estimated_completion: 5.minutes.from_now
    }
  end

  def response
    render json: @result, status: :accepted
  end
end
```

## 🔐 Security Checks

ReactiveActions provides a comprehensive security system through the `SecurityChecks` module, allowing you to define custom security filters that run before your actions execute.

### Basic Security Checks

Add security checks to your actions using the `security_check` class method:

```ruby
# app/reactive_actions/protected_action.rb
class ProtectedAction < ReactiveActions::ReactiveAction
  # Single security check
  security_check :require_authentication

  def action
    @result = { message: "This action requires authentication" }
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Authentication required" unless current_user
  end
end
```

### Multiple Security Checks

Chain multiple security checks for layered protection:

```ruby
# app/reactive_actions/admin_action.rb
class AdminAction < ReactiveActions::ReactiveAction
  # Multiple security checks run in order
  security_check :require_authentication
  security_check :require_admin_role

  def action
    @result = { message: "Admin-only action executed successfully" }
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Please log in" unless current_user
  end

  def require_admin_role
    raise ReactiveActions::SecurityCheckError, "Admin access required" unless current_user.admin?
  end
end
```

### Lambda-Based Security Checks

Use inline lambdas for simple or dynamic security checks:

```ruby
# app/reactive_actions/ownership_action.rb
class OwnershipAction < ReactiveActions::ReactiveAction
  # Inline lambda security check
  security_check -> {
    raise ReactiveActions::SecurityCheckError, "Must be logged in" unless current_user
    
    if action_params[:user_id].present?
      unless current_user.id.to_s == action_params[:user_id].to_s
        raise ReactiveActions::SecurityCheckError, "Can only access your own data"
      end
    end
  }

  def action
    @result = { message: "Ownership check passed" }
  end

  def response
    render json: @result
  end
end
```

### Conditional Security Checks

Apply security checks conditionally using `:if`, `:unless`, `:only`, or `:except`:

```ruby
# app/reactive_actions/conditional_action.rb
class ConditionalAction < ReactiveActions::ReactiveAction
  # Always require authentication
  security_check :require_authentication
  
  # Only require special access if special mode is enabled
  security_check :require_special_access, if: -> { action_params[:special_mode] == "true" }
  
  # Skip ownership check for admin users
  security_check :require_ownership, unless: -> { current_user&.admin? }

  def action
    @result = { message: "Conditional security checks passed" }
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Authentication required" unless current_user
  end

  def require_special_access
    unless current_user.special_access?
      raise ReactiveActions::SecurityCheckError, "Special access required"
    end
  end

  def require_ownership
    resource_id = action_params[:resource_id]
    resource = current_user.resources.find_by(id: resource_id)
    raise ReactiveActions::SecurityCheckError, "Resource not found" unless resource
  end
end
```

### Skipping Security Checks

For public actions that don't need any security checks:

```ruby
# app/reactive_actions/public_action.rb
class PublicAction < ReactiveActions::ReactiveAction
  # Skip all security checks for this action
  skip_security_checks

  def action
    @result = { message: "This is a public action" }
  end

  def response
    render json: @result
  end
end
```

### Security Check Options

The `security_check` method supports several options for fine-grained control:

```ruby
class ExampleAction < ReactiveActions::ReactiveAction
  # Run only for specific actions (if you have multiple action methods)
  security_check :check_method, only: [:create, :update]
  
  # Skip for specific actions
  security_check :check_method, except: [:index, :show]
  
  # Conditional execution
  security_check :check_method, if: :some_condition?
  security_check :check_method, unless: :some_other_condition?
  
  # Combine conditions
  security_check :check_method, if: -> { params[:secure] == "true" }, unless: :development_mode?

  private

  def check_method
    # Your security logic here
  end

  def some_condition?
    # Your condition logic
  end

  def development_mode?
    Rails.env.development?
  end
end
```

### Security Error Handling

Security checks raise `ReactiveActions::SecurityCheckError` when they fail. This error is automatically caught and returned as a proper HTTP response:

```json
{
  "success": false,
  "error": {
    "type": "SecurityCheckError",
    "message": "Authentication required",
    "code": "SECURITY_CHECK_FAILED"
  }
}
```

### Real-World Security Examples

#### User Resource Access Control
```ruby
# app/reactive_actions/update_profile_action.rb
class UpdateProfileAction < ReactiveActions::ReactiveAction
  security_check :require_authentication
  security_check :verify_profile_ownership

  def action
    profile = current_user.profile
    profile.update!(action_params.slice(:bio, :website, :location))
    @result = { profile: profile.as_json }
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Please log in" unless current_user
  end

  def verify_profile_ownership
    profile_id = action_params[:profile_id]
    return unless profile_id.present? # Skip check if no profile_id specified
    
    unless current_user.profile.id.to_s == profile_id.to_s
      raise ReactiveActions::SecurityCheckError, "Can only update your own profile"
    end
  end
end
```

#### Role-Based Access Control
```ruby
# app/reactive_actions/moderate_content_action.rb
class ModerateContentAction < ReactiveActions::ReactiveAction
  security_check :require_authentication
  security_check :require_moderator_role

  def action
    content = Content.find(action_params[:content_id])
    content.update!(status: action_params[:status], 
                   moderated_by: current_user.id)
    @result = { content: content.as_json }
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Authentication required" unless current_user
  end

  def require_moderator_role
    unless current_user.moderator? || current_user.admin?
      raise ReactiveActions::SecurityCheckError, "Moderator access required"
    end
  end
end
```

#### API Key Validation
```ruby
# app/reactive_actions/api_action.rb
class ApiAction < ReactiveActions::ReactiveAction
  security_check :validate_api_key
  security_check :check_rate_limit

  def action
    @result = { data: "API response data" }
  end

  def response
    render json: @result
  end

  private

  def validate_api_key
    api_key = action_params[:api_key] || controller.request.headers['X-API-Key']
    
    unless api_key.present? && ApiKey.valid?(api_key)
      raise ReactiveActions::SecurityCheckError, "Invalid or missing API key"
    end
    
    @api_key = ApiKey.find_by(key: api_key)
  end

  def check_rate_limit
    return unless @api_key
    
    if @api_key.rate_limit_exceeded?
      raise ReactiveActions::SecurityCheckError, "Rate limit exceeded"
    end
  end
end
```

## 🚦 Rate Limiting

ReactiveActions provides comprehensive rate limiting functionality to protect your application from abuse and ensure fair resource usage. Rate limiting is **disabled by default** and must be explicitly enabled in your configuration.

### 🔧 Configuration

Rate limiting is configured in your `config/initializers/reactive_actions.rb` file:

```ruby
ReactiveActions.configure do |config|
  # Enable rate limiting functionality
  config.rate_limiting_enabled = true
  
  # Enable global controller-level rate limiting
  config.global_rate_limiting_enabled = true
  config.global_rate_limit = 600                # 600 requests per window
  config.global_rate_limit_window = 1.minute    # per minute
  
  # Optional: Custom rate limit key generator
  config.rate_limit_key_generator = ->(request, action_name) do
    user_id = request.headers['X-User-ID'] || 'anonymous'
    "#{action_name}:user:#{user_id}"
  end
end
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `rate_limiting_enabled` | `false` | Master switch for all rate limiting features |
| `global_rate_limiting_enabled` | `false` | Enable controller-level rate limiting |
| `global_rate_limit` | `600` | Global rate limit (requests per window) |
| `global_rate_limit_window` | `1.minute` | Time window for global rate limiting |
| `rate_limit_key_generator` | `nil` | Custom key generator proc |

### 🎯 Action-Level Rate Limiting

Include the `RateLimiter` concern in your actions to add rate limiting functionality:

```ruby
# app/reactive_actions/api_action.rb
class ApiAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    # Basic rate limiting: 10 requests per minute per user
    rate_limit!(key: "user:#{current_user&.id}", limit: 10, window: 1.minute)
    
    @result = { data: "API response" }
  end

  def response
    render json: @result
  end
end
```

### 🔑 Key-Based Rate Limiting

Rate limiting works with different key strategies:

```ruby
class FlexibleRateLimitAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    case action_params[:rate_limit_type]
    when 'user'
      # User-specific rate limiting
      rate_limit!(key: "user:#{current_user.id}", limit: 100, window: 1.hour)
      
    when 'ip'
      # IP-based rate limiting
      rate_limit!(key: "ip:#{controller.request.remote_ip}", limit: 50, window: 15.minutes)
      
    when 'api_key'
      # API key-based rate limiting
      api_key = action_params[:api_key]
      rate_limit!(key: "api:#{api_key}", limit: 1000, window: 1.hour)
      
    when 'global'
      # Global rate limiting for expensive operations
      rate_limit!(key: "global:expensive_operation", limit: 10, window: 1.minute)
    end
    
    @result = { message: "Rate limit check passed" }
  end

  def response
    render json: @result
  end
end
```

### 💰 Cost-Based Rate Limiting

Assign different costs to different operations:

```ruby
class CostBasedRateLimitAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    operation_type = action_params[:operation]
    user_key = "user:#{current_user.id}"
    
    case operation_type
    when 'search'
      # Light operation: cost 1
      rate_limit!(key: user_key, limit: 100, window: 1.minute, cost: 1)
      
    when 'export'
      # Medium operation: cost 5
      rate_limit!(key: user_key, limit: 100, window: 1.minute, cost: 5)
      
    when 'bulk_import'
      # Heavy operation: cost 20
      rate_limit!(key: user_key, limit: 100, window: 1.minute, cost: 20)
      
    when 'report_generation'
      # Very heavy operation: cost 50
      rate_limit!(key: user_key, limit: 100, window: 1.minute, cost: 50)
    end
    
    perform_operation(operation_type)
  end

  def response
    render json: @result
  end

  private

  def perform_operation(type)
    @result = { operation: type, status: 'completed' }
  end
end
```

### 📊 Rate Limiting Status and Management

Check and manage rate limiting status:

```ruby
class RateLimitManagementAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    user_key = "user:#{current_user.id}"
    
    case action_params[:action_type]
    when 'status'
      # Check current rate limit status without consuming a request
      status = rate_limit_status(key: user_key, limit: 100, window: 1.hour)
      @result = { rate_limit_status: status }
      
    when 'check_would_exceed'
      # Check if a specific cost would exceed the limit
      cost = action_params[:cost] || 1
      would_exceed = rate_limit_would_exceed?(
        key: user_key, 
        limit: 100, 
        window: 1.hour, 
        cost: cost
      )
      @result = { would_exceed: would_exceed, cost: cost }
      
    when 'reset'
      # Reset rate limit for the user (admin functionality)
      reset_rate_limit!(key: user_key, window: 1.hour)
      @result = { message: "Rate limit reset for user", user_id: current_user.id }
      
    when 'remaining'
      # Get remaining requests
      remaining = rate_limit_remaining(key: user_key, limit: 100, window: 1.hour)
      @result = { remaining: remaining }
    end
  end

  def response
    render json: @result
  end
end
```

### 🌐 Global Controller-Level Rate Limiting

Enable global rate limiting across all ReactiveActions requests:

```ruby
# config/initializers/reactive_actions.rb
ReactiveActions.configure do |config|
  config.rate_limiting_enabled = true
  config.global_rate_limiting_enabled = true
  config.global_rate_limit = 600              # 10 requests per second
  config.global_rate_limit_window = 1.minute  # per minute window
end
```

This automatically adds rate limiting to all ReactiveActions controller requests with appropriate headers:

```
X-RateLimit-Limit: 600
X-RateLimit-Remaining: 599
X-RateLimit-Window: 60
X-RateLimit-Reset: 1672531260
Retry-After: 30  # (when rate limited)
```

### 🎛️ Advanced Rate Limiting Features

#### Scoped Keys
```ruby
class ScopedRateLimitAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    # Create scoped keys for different features
    api_key = rate_limit_key_for('api', identifier: current_user.id)
    search_key = rate_limit_key_for('search', identifier: current_user.id)
    upload_key = rate_limit_key_for('upload', identifier: current_user.id)
    
    case action_params[:feature]
    when 'api'
      rate_limit!(key: api_key, limit: 1000, window: 1.hour)
    when 'search'
      rate_limit!(key: search_key, limit: 100, window: 1.minute)
    when 'upload'
      rate_limit!(key: upload_key, limit: 10, window: 1.minute)
    end
    
    @result = { feature: action_params[:feature], status: 'allowed' }
  end

  def response
    render json: @result
  end
end
```

#### Custom Key Generators
```ruby
# config/initializers/reactive_actions.rb
ReactiveActions.configure do |config|
  config.rate_limiting_enabled = true
  
  # Custom key generator for sophisticated rate limiting
  config.rate_limit_key_generator = ->(request, action_name) do
    # Multi-factor key generation
    user_id = request.headers['X-User-ID']
    api_key = request.headers['X-API-Key']
    user_tier = request.headers['X-User-Tier'] || 'basic'
    
    if api_key.present?
      # API requests get higher limits
      "api:#{api_key}:#{action_name}"
    elsif user_id.present?
      # User-based with tier consideration
      "user:#{user_tier}:#{user_id}:#{action_name}"
    else
      # Anonymous requests get IP-based limiting
      "ip:#{request.remote_ip}:#{action_name}"
    end
  end
end
```

#### Rate Limiting with Security Integration
```ruby
class SecureRateLimitedAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter
  
  # Security checks run before rate limiting
  security_check :require_authentication
  
  def action
    # Apply different limits based on user role
    limit = determine_user_limit
    window = determine_user_window
    
    rate_limit!(
      key: "role:#{current_user.role}:#{current_user.id}", 
      limit: limit, 
      window: window
    )
    
    perform_secure_operation
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Authentication required" unless current_user
  end

  def determine_user_limit
    case current_user.role
    when 'admin'
      1000  # Admins get higher limits
    when 'premium'
      500   # Premium users get medium limits
    when 'basic'
      100   # Basic users get standard limits
    else
      50    # Default for other roles
    end
  end

  def determine_user_window
    current_user.role == 'admin' ? 1.minute : 5.minutes
  end

  def perform_secure_operation
    @result = { 
      message: "Secure operation completed",
      user_role: current_user.role,
      rate_limit_applied: true
    }
  end
end
```

### 🏗️ Custom Controller Rate Limiting

Add rate limiting to your own controllers:

```ruby
class ApiController < ApplicationController
  include ReactiveActions::Controller::RateLimiter
  
  # Rate limit specific actions
  rate_limit_action :show, limit: 100, window: 1.minute
  rate_limit_action :create, limit: 10, window: 1.minute, only: [:create]
  
  # Skip rate limiting for certain actions
  skip_rate_limiting :health_check, :status

  def show
    # This action is automatically rate limited
    render json: { data: "API response" }
  end

  def create
    # This action has stricter rate limiting
    render json: { created: true }
  end

  def health_check
    # This action skips rate limiting
    render json: { status: "ok" }
  end
end
```

### 📈 Rate Limiting Monitoring and Logging

Monitor rate limiting events:

```ruby
class MonitoredRateLimitAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    user_key = "user:#{current_user.id}"
    
    begin
      # Log rate limiting attempt
      log_rate_limit_event('attempt', {
        user_id: current_user.id,
        action: 'api_call'
      })
      
      rate_limit!(key: user_key, limit: 100, window: 1.hour)
      
      # Log successful rate limit check
      log_rate_limit_event('success', {
        user_id: current_user.id,
        remaining: rate_limit_remaining(key: user_key, limit: 100, window: 1.hour)
      })
      
      @result = { status: 'success' }
      
    rescue ReactiveActions::RateLimitExceededError => e
      # Log rate limit exceeded
      log_rate_limit_event('exceeded', {
        user_id: current_user.id,
        limit: e.limit,
        current: e.current,
        retry_after: e.retry_after
      })
      
      raise e
    end
  end

  def response
    render json: @result
  end
end
```

### 🎛️ Rate Limiting Configuration Options

#### Enable Rate Limiting During Installation

```bash
# Enable rate limiting during installation
$ rails generate reactive_actions:install --enable-rate-limiting --enable-global-rate-limiting --global-rate-limit=1000
```

#### Runtime Configuration Checks

```ruby
class ConditionalRateLimitAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    # Check if rate limiting is enabled before applying
    if rate_limiting_enabled?
      rate_limit!(key: "feature:#{action_params[:feature]}", limit: 50, window: 1.minute)
      @result = { rate_limiting: 'enabled', status: 'limited' }
    else
      @result = { rate_limiting: 'disabled', status: 'unlimited' }
    end
  end

  def response
    render json: @result
  end
end
```

### ⚡ Rate Limiting Error Handling

Rate limiting errors are automatically handled and return structured responses:

```json
{
  "success": false,
  "error": {
    "type": "RateLimitExceededError",
    "message": "Rate limit exceeded: 101/100 requests in 1 minute",
    "code": "RATE_LIMIT_EXCEEDED",
    "limit": 100,
    "window": 60,
    "retry_after": 45
  }
}
```

### 🚀 Performance Considerations

Rate limiting uses Rails cache for storage:

- **Production**: Use Redis or Memcached for distributed caching
- **Development**: Uses memory store automatically
- **Test**: Uses memory store to avoid cache pollution

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

### 🔧 Rate Limiting Best Practices

1. **Start Conservative**: Begin with generous limits and tighten based on usage patterns
2. **Use Appropriate Windows**: Shorter windows (1-5 minutes) for responsive limiting
3. **Different Limits for Different Operations**: Heavier operations should cost more
4. **Monitor and Alert**: Set up monitoring for rate limit violations
5. **Graceful Degradation**: Provide meaningful error messages and retry guidance
6. **User Tier Consideration**: Different limits for different user tiers
7. **API Documentation**: Document rate limits in your API documentation

## 💻 Simple DOM Binding Examples

### Basic Button Actions

```html
<!-- Simple button click -->
<button reactive-action="click->test">Test Action</button>

<!-- Button with data attributes -->
<button reactive-action="click->update_status" 
        reactive-action-status="active">
  Update Status
</button>

<!-- Button with HTTP method -->
<button reactive-action="click->delete#remove_item">Delete Item</button>
```

### Form Examples

```html
<!-- Simple form submission -->
<form reactive-action="submit->create_item">
  <input name="title" type="text" required>
  <button type="submit">Create</button>
</form>

<!-- Form with custom data -->
<form reactive-action="submit->post#save_data" 
      reactive-action-category="important">
  <input name="message" type="text" required>
  <button type="submit">Save</button>
</form>
```

### Input Events

```html
<!-- Live search -->
<input type="text" 
       reactive-action="input->search" 
       placeholder="Search...">

<!-- Select dropdown -->
<select reactive-action="change->filter_results">
  <option value="all">All Items</option>
  <option value="active">Active Only</option>
</select>
```

### Success/Error Handling

```html
<button reactive-action="click->test"
        reactive-action-success="showSuccess"
        reactive-action-error="showError">
  Test with Callbacks
</button>

<script>
function showSuccess(response) {
  alert('Success: ' + response.message);
}

function showError(error) {
  alert('Error: ' + error.message);
}
</script>
```

## Security

ReactiveActions implements several security measures:

### 🔒 Built-in Security Features

- **Parameter sanitization** - Input validation and safe patterns
- **CSRF protection** - Automatic Rails CSRF token handling
- **Code injection prevention** - Sanitized class names and parameters
- **Length limits** - Prevents memory exhaustion attacks

### 🛡️ Security Best Practices

```ruby
# Always validate user permissions
class SecureAction < ReactiveActions::ReactiveAction
  security_check :require_authentication
  security_check :validate_ownership

  def action
    # Validate and sanitize inputs
    user_id = action_params[:user_id].to_i
    raise ReactiveActions::InvalidParametersError if user_id <= 0
    
    # Use strong parameters
    permitted_params = action_params.slice(:name, :email).permit!
    
    @result = User.find(user_id).update(permitted_params)
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError unless current_user
  end

  def validate_ownership
    user_id = action_params[:user_id].to_i
    unless current_user.id == user_id || current_user.admin?
      raise ReactiveActions::SecurityCheckError, "Access denied"
    end
  end
end
```

## ❌ Error Handling

ReactiveActions provides structured error handling:

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

**Error Types:**
- `ActionNotFoundError` - Action doesn't exist
- `MissingParameterError` - Required parameters missing
- `InvalidParametersError` - Invalid parameter format
- `UnauthorizedError` - Permission denied
- `ActionExecutionError` - Runtime execution error
- `SecurityCheckError` - Security check failed
- `RateLimitExceededError` - Rate limit exceeded

## 🚄 Rails 8 Compatibility

Designed specifically for Rails 8:
- ✅ **Propshaft** - Modern asset pipeline
- ✅ **Importmap** - Native ES modules
- ✅ **Rails 8 conventions** - Current best practices
- ✅ **Modern JavaScript** - ES6+ features
- ✅ **Backward compatibility** - Works with Sprockets

## 🗺️ Roadmap & Future Improvements

Planned features:
- Enhanced error handling
- Action composition for complex workflows
- Built-in testing utilities
- Auto-generated API documentation

## 🛠️ Development

After checking out the repo:

```bash
$ bundle install
$ bundle exec rspec  # Run tests
$ bin/console        # Interactive prompt
```

## 🧪 Testing

Run the test suite:

```bash
$ bundle exec rspec
```

**Note**: The dummy application is only available in the source repository.

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/IstvanMs/reactive-actions.

## 📄 License

The gem is available as open source under the terms of the MIT License.