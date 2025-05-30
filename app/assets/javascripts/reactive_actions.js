// ReactiveActions JavaScript Client for Rails 8
// ES Module compatible version

class ReactiveActionsClient {
  constructor() {
    this.baseUrl = '/reactive_actions/execute';
  }

  // Get CSRF token from meta tag
  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.getAttribute('content') : null;
  }

  // Execute an action with parameters
  async execute(actionName, actionParams = {}, options = {}) {
    const method = options.method || 'POST';
    const contentType = options.contentType || 'application/json';
    
    // Build request options
    const requestOptions = {
      method: method,
      headers: {
        'Content-Type': contentType,
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    };
    
    // Add CSRF token if available
    const csrfToken = this.getCSRFToken();
    if (csrfToken) {
      requestOptions.headers['X-CSRF-Token'] = csrfToken;
    }
    
    // Build URL or prepare body based on HTTP method
    let url = this.baseUrl;
    if (['GET', 'HEAD'].includes(method.toUpperCase())) {
      // For GET requests, append parameters to URL
      const params = new URLSearchParams({
        action_name: actionName,
        action_params: JSON.stringify(actionParams)
      });
      url = `${url}?${params.toString()}`;
    } else {
      // For other methods, send in request body
      requestOptions.body = JSON.stringify({
        action_name: actionName,
        action_params: actionParams
      });
    }
    
    try {
      const response = await fetch(url, requestOptions);
      const data = await response.json();
      
      // Add response status and ok to the result
      return {
        ...data,
        status: response.status,
        ok: response.ok
      };
    } catch (error) {
      console.error('ReactiveActions error:', error);
      throw error;
    }
  }

  // Convenience methods for different HTTP verbs
  async get(actionName, actionParams = {}, options = {}) {
    return this.execute(actionName, actionParams, { ...options, method: 'GET' });
  }

  async post(actionName, actionParams = {}, options = {}) {
    return this.execute(actionName, actionParams, { ...options, method: 'POST' });
  }

  async put(actionName, actionParams = {}, options = {}) {
    return this.execute(actionName, actionParams, { ...options, method: 'PUT' });
  }

  async patch(actionName, actionParams = {}, options = {}) {
    return this.execute(actionName, actionParams, { ...options, method: 'PATCH' });
  }

  async delete(actionName, actionParams = {}, options = {}) {
    return this.execute(actionName, actionParams, { ...options, method: 'DELETE' });
  }
}

// Create and export the instance
const ReactiveActions = new ReactiveActionsClient();

// For backward compatibility, also expose as global
if (typeof window !== 'undefined') {
  window.ReactiveActions = ReactiveActions;
}

// ES Module export
export default ReactiveActions;