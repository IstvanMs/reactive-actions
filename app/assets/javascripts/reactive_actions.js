// ReactiveActions JavaScript Client for Rails 8
// ES Module compatible version with manual initialization

class ReactiveActionsClient {
  constructor(options = {}) {
    // Default configuration
    this.config = {
      baseUrl: '/reactive_actions/execute',
      enableAutoBinding: true,
      enableMutationObserver: true,
      defaultHttpMethod: 'POST',
      ...options
    };
    
    this.boundElements = new WeakSet();
    this.initialized = false;
  }

  // Update configuration
  configure(options = {}) {
    this.config = { ...this.config, ...options };
    
    // If baseUrl changed, update it
    if (options.baseUrl) {
      this.baseUrl = options.baseUrl;
    }
    
    return this;
  }

  // Get current configuration
  getConfig() {
    return { ...this.config };
  }

  // Initialize DOM bindings when called - must be called manually
  initialize(options = {}) {
    // Update configuration if options provided
    if (Object.keys(options).length > 0) {
      this.configure(options);
    }
    
    // Skip if already initialized
    if (this.initialized) return this;
    
    // Only bind if auto-binding is enabled
    if (this.config.enableAutoBinding) {
      this.bindExistingElements();
      
      if (this.config.enableMutationObserver) {
        this.setupMutationObserver();
      }
    }
    
    this.initialized = true;
    return this;
  }

  // Force re-initialization (useful after configuration changes)
  reinitialize() {
    this.initialized = false;
    this.boundElements = new WeakSet();
    this.initialize();
  }

  // Bind all existing elements with reactive-action attributes
  bindExistingElements() {
    const elements = document.querySelectorAll('[reactive-action]');
    elements.forEach(element => this.bindElement(element));
  }

  // Set up mutation observer to handle dynamically added elements
  setupMutationObserver() {
    const observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
        mutation.addedNodes.forEach(node => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            // Check if the node itself has reactive-action
            if (node.hasAttribute && node.hasAttribute('reactive-action')) {
              this.bindElement(node);
            }
            // Check for child elements with reactive-action
            const children = node.querySelectorAll ? node.querySelectorAll('[reactive-action]') : [];
            children.forEach(child => this.bindElement(child));
          }
        });
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  // Bind a single element to reactive actions
  bindElement(element) {
    // Skip if already bound
    if (this.boundElements.has(element)) return;

    const actionValue = element.getAttribute('reactive-action');
    if (!actionValue) return;

    // Parse actions - support multiple actions separated by spaces
    const actions = this.parseActions(actionValue);
    
    actions.forEach(({ event, httpMethod, actionName }) => {
      const listener = this.createActionListener(element, actionName, httpMethod);
      
      // Handle special cases for form submission
      if (event === 'submit' && element.tagName.toLowerCase() === 'form') {
        element.addEventListener('submit', (e) => {
          e.preventDefault();
          listener(e);
        });
      } else {
        element.addEventListener(event, listener);
      }
    });

    // Mark as bound
    this.boundElements.add(element);
  }

  // Parse action string(s) - supports "click->action_name", "click->post#action_name", or multiple actions
  parseActions(actionValue) {
    const actions = [];
    const actionPairs = actionValue.trim().split(/\s+/);
    
    actionPairs.forEach(pair => {
      // Match patterns: "event->action", "event->method#action"
      const match = pair.match(/^(\w+)->((?:(\w+)#)?(.+))$/);
      if (match) {
        const [, event, , httpMethod, actionName] = match;
        actions.push({ 
          event, 
          httpMethod: httpMethod ? httpMethod.toUpperCase() : this.config.defaultHttpMethod,
          actionName 
        });
      }
    });
    
    return actions;
  }

  // Create event listener for an action
  createActionListener(element, actionName, httpMethod = null) {
    return async (event) => {
      try {
        // Add loading state
        this.setLoadingState(element, true);

        // Extract data attributes
        const actionParams = this.extractDataAttributes(element);
        
        // Add form data if it's a form element
        if (element.tagName.toLowerCase() === 'form') {
          const formData = new FormData(element);
          for (const [key, value] of formData.entries()) {
            actionParams[key] = value;
          }
        }
        
        // Add input value for input elements on change events
        if (['input', 'select', 'textarea'].includes(element.tagName.toLowerCase()) && 
            ['change', 'input'].includes(event.type)) {
          actionParams.value = element.value;
        }

        // Execute the action using the existing method with specified HTTP method
        const method = httpMethod || this.config.defaultHttpMethod;
        const response = await this.execute(actionName, actionParams, { method });
        
        // Handle response
        this.handleActionResponse(element, response, event);
        
      } catch (error) {
        this.handleActionError(element, error, event);
      } finally {
        this.setLoadingState(element, false);
      }
    };
  }

  // Extract data attributes from element
  extractDataAttributes(element) {
    const data = {};
    const attributes = element.attributes;
    
    for (const attr of attributes) {
      if (attr.name.startsWith('reactive-action-') && 
          !['reactive-action', 'reactive-action-success', 'reactive-action-error'].includes(attr.name)) {
        const key = attr.name
          .replace('reactive-action-', '')
          .replace(/-/g, '_'); // Convert kebab-case to snake_case
        data[key] = attr.value;
      }
    }
    
    return data;
  }

  // Set loading state on element
  setLoadingState(element, loading) {
    if (loading) {
      element.classList.add('reactive-loading');
      if (element.tagName.toLowerCase() === 'button' || element.tagName.toLowerCase() === 'input') {
        element.disabled = true;
      }
      // Store original text if it's a button or link
      if (['button', 'a'].includes(element.tagName.toLowerCase())) {
        element.dataset.originalText = element.textContent;
        element.textContent = element.dataset.loadingText || 'Loading...';
      }
    } else {
      element.classList.remove('reactive-loading');
      if (element.tagName.toLowerCase() === 'button' || element.tagName.toLowerCase() === 'input') {
        element.disabled = false;
      }
      // Restore original text
      if (element.dataset.originalText) {
        element.textContent = element.dataset.originalText;
        delete element.dataset.originalText;
      }
    }
  }

  // Handle successful action response
  handleActionResponse(element, response, event) {
    // Dispatch custom event
    const customEvent = new CustomEvent('reactive-action:success', {
      detail: { response, element, originalEvent: event },
      bubbles: true
    });
    element.dispatchEvent(customEvent);

    // Handle success callback if specified
    const successCallback = element.getAttribute('reactive-action-success');
    if (successCallback && typeof window[successCallback] === 'function') {
      window[successCallback](response, element, event);
    }

    // Log successful responses that aren't ok
    if (!response.ok) {
      console.warn('ReactiveActions response not ok:', response);
    }
  }

  // Handle action errors
  handleActionError(element, error, event) {
    console.error('ReactiveActions error:', error);
    
    // Dispatch custom event
    const customEvent = new CustomEvent('reactive-action:error', {
      detail: { error, element, originalEvent: event },
      bubbles: true
    });
    element.dispatchEvent(customEvent);

    // Handle error callback if specified
    const errorCallback = element.getAttribute('reactive-action-error');
    if (errorCallback && typeof window[errorCallback] === 'function') {
      window[errorCallback](error, element, event);
    }
  }

  // Get CSRF token from meta tag
  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.getAttribute('content') : null;
  }

  // Execute an action with parameters
  async execute(actionName, actionParams = {}, options = {}) {
    const method = options.method || this.config.defaultHttpMethod;
    const contentType = options.contentType || 'application/json';
    
    // Use configured baseUrl
    const baseUrl = this.config.baseUrl;
    
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
    let url = baseUrl;
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

// ES Module export
export default ReactiveActionsClient;

// Global export
if (typeof window !== 'undefined') {
  window.ReactiveActionsClient = ReactiveActionsClient;
}