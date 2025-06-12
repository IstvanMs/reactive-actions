# ReactiveActions

ReactiveActions is a Rails gem that provides a framework for handling reactive actions in your Rails application with Stimulus-style DOM binding support.

## 🚧 Status

This gem is currently in alpha (0.1.0-alpha.2). The API may change between versions.

## 📦 Installation

Add this line to your application's Gemfile:

```ruby
gem 'reactive-actions', '0.1.0-alpha.2'
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

## 💻 Complete DOM Binding Examples

### User Management Interface

```html
<!-- User List with Actions -->
<div class="user-list">
  <% @users.each do |user| %>
    <div class="user-card" id="user-<%= user.id %>">
      <h3><%= user.name %></h3>
      <p><%= user.email %></p>
      
      <!-- Update user -->
      <button reactive-action="click->put#update_user"
              reactive-action-user-id="<%= user.id %>"
              reactive-action-name="<%= user.name %>"
              reactive-action-success="handleUserUpdate">
        Quick Update
      </button>
      
      <!-- Delete user -->
      <button reactive-action="click->delete#delete_user"
              reactive-action-user-id="<%= user.id %>"
              reactive-action-success="handleUserDelete"
              class="danger">
        Delete
      </button>
      
      <!-- Show preview on hover -->
      <div reactive-action="mouseenter->get#show_user_preview mouseleave->post#hide_preview"
           reactive-action-user-id="<%= user.id %>"
           reactive-action-target="preview-<%= user.id %>">
        <img src="<%= user.avatar %>" alt="Hover for details">
      </div>
    </div>
  <% end %>
</div>

<!-- Live Search -->
<div class="search-container">
  <input type="text" 
         reactive-action="input->get#search_users"
         reactive-action-min-length="2"
         reactive-action-success="updateSearchResults"
         placeholder="Search users...">
  
  <div id="search-results"></div>
</div>

<!-- Create User Form -->
<form reactive-action="submit->post#create_user"
      reactive-action-success="handleUserCreate">
  <input name="name" type="text" placeholder="Name" required>
  <input name="email" type="email" placeholder="Email" required>
  <button type="submit">Create User</button>
</form>

<script>
function handleUserUpdate(response, element, event) {
  if (response.success) {
    // Update the UI without page refresh
    const userCard = element.closest('.user-card');
    userCard.querySelector('h3').textContent = response.user.name;
    
    // Show success message
    showFlash('User updated successfully!', 'success');
  }
}

function handleUserDelete(response, element, event) {
  if (response.success) {
    // Remove the user card from the UI
    const userCard = element.closest('.user-card');
    userCard.remove();
    
    showFlash('User deleted successfully!', 'success');
  }
}

function handleUserCreate(response, element, event) {
  if (response.success) {
    // Reset the form
    element.reset();
    
    // Add new user to the list or refresh
    location.reload(); // Or dynamically add to the list
    
    showFlash('User created successfully!', 'success');
  }
}

function updateSearchResults(response, element, event) {
  const resultsDiv = document.getElementById('search-results');
  resultsDiv.innerHTML = response.users.map(user => 
    `<div class="search-result">
       <strong>${user.name}</strong> - ${user.email}
     </div>`
  ).join('');
}

function showFlash(message, type) {
  // Your flash message implementation
  console.log(`${type}: ${message}`);
}
</script>
```

### E-commerce Product Interactions

```html
<!-- Product Cards -->
<div class="products-grid">
  <% @products.each do |product| %>
    <div class="product-card">
      <h3><%= product.name %></h3>
      <p class="price">$<%= product.price %></p>
      
      <!-- Add to cart -->
      <button reactive-action="click->post#add_to_cart"
              reactive-action-product-id="<%= product.id %>"
              reactive-action-quantity="1"
              reactive-action-success="updateCartCount">
        Add to Cart
      </button>
      
      <!-- Wishlist toggle -->
      <button reactive-action="click->post#toggle_wishlist"
              reactive-action-product-id="<%= product.id %>"
              reactive-action-success="toggleWishlistUI"
              class="<%= 'wishlisted' if current_user.wishlist.include?(product) %>">
        ♥ Wishlist
      </button>
      
      <!-- Quick view on hover -->
      <div reactive-action="mouseenter->get#quick_view"
           reactive-action-product-id="<%= product.id %>"
           reactive-action-success="showQuickView">
        <img src="<%= product.image %>" alt="<%= product.name %>">
      </div>
      
      <!-- Quantity selector -->
      <select reactive-action="change->put#update_cart_quantity"
              reactive-action-product-id="<%= product.id %>"
              reactive-action-success="updateCartTotal">
        <% (1..10).each do |qty| %>
          <option value="<%= qty %>"><%= qty %></option>
        <% end %>
      </select>
    </div>
  <% end %>
</div>

<!-- Product Filter -->
<div class="filters">
  <select reactive-action="change->get#filter_products"
          reactive-action-success="updateProductGrid">
    <option value="">All Categories</option>
    <option value="electronics">Electronics</option>
    <option value="clothing">Clothing</option>
    <option value="books">Books</option>
  </select>
  
  <input type="range" 
         reactive-action="input->get#filter_by_price"
         reactive-action-success="updateProductGrid"
         min="0" max="1000" step="10">
</div>
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
  def action
    raise ReactiveActions::UnauthorizedError unless current_user&.admin?
    
    # Validate and sanitize inputs
    user_id = action_params[:user_id].to_i
    raise ReactiveActions::InvalidParametersError if user_id <= 0
    
    # Use strong parameters
    permitted_params = action_params.slice(:name, :email).permit!
    
    @result = User.find(user_id).update(permitted_params)
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

## 🚄 Rails 8 Compatibility

Designed specifically for Rails 8:
- ✅ **Propshaft** - Modern asset pipeline
- ✅ **Importmap** - Native ES modules
- ✅ **Rails 8 conventions** - Current best practices
- ✅ **Modern JavaScript** - ES6+ features
- ✅ **Backward compatibility** - Works with Sprockets

## 🗺️ Roadmap & Future Improvements

Planned features:
- Security hooks for authentication/authorization
- Rate limiting and throttling
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