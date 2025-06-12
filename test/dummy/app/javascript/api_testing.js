(function() {
  'use strict';
  
  // Prevent multiple execution by checking if already initialized
  if (window.ReactiveActionsApiTestingInitialized) {
    console.log('ReactiveActions API Testing: Already initialized, skipping script execution');
    return;
  }
  
  // Namespace for API testing functions to avoid global pollution
  window.ReactiveActionsApiTesting = window.ReactiveActionsApiTesting || {
    
    executeAction: async function() {
      const actionName = document.getElementById('actionName').value.trim();
      const actionDataInput = document.getElementById('actionData').value.trim();
      const httpMethod = document.getElementById('httpMethod').value;
      const resultElement = document.getElementById('result');
      
      // Validate action name
      if (!actionName) {
        resultElement.textContent = 'Error: Action name is required';
        return;
      }
      
      // Parse JSON data
      let actionData = {};
      if (actionDataInput) {
        try {
          actionData = JSON.parse(actionDataInput);
        } catch (error) {
          resultElement.textContent = `Error: Invalid JSON data - ${error.message}`;
          return;
        }
      }
      
      resultElement.textContent = `Executing action "${actionName}" using ${httpMethod.toUpperCase()}...`;
      
      try {
        const startTime = performance.now();
        let response;
        
        // Use the selected HTTP method
        switch (httpMethod) {
          case 'get':
            response = await ReactiveActions.get(actionName, actionData);
            break;
          case 'post':
            response = await ReactiveActions.post(actionName, actionData);
            break;
          case 'put':
            response = await ReactiveActions.put(actionName, actionData);
            break;
          case 'patch':
            response = await ReactiveActions.patch(actionName, actionData);
            break;
          case 'delete':
            response = await ReactiveActions.delete(actionName, actionData);
            break;
          default:
            response = await ReactiveActions.execute(actionName, actionData);
            break;
        }
        
        const endTime = performance.now();
        resultElement.textContent = JSON.stringify({
          success: true,
          httpMethod: httpMethod.toUpperCase(),
          actionName: actionName,
          params: actionData,
          response: response,
          executionTime: `${(endTime - startTime).toFixed(2)}ms`,
          loadedVia: 'Turbo Frame'
        }, null, 2);
        
      } catch (error) {
        resultElement.textContent = JSON.stringify({
          success: false,
          httpMethod: httpMethod.toUpperCase(),
          actionName: actionName,
          params: actionData,
          error: error.message,
          stack: error.stack,
          loadedVia: 'Turbo Frame'
        }, null, 2);
      }
    },
    
    clearApiLog: function() {
      document.getElementById('result').textContent = 'Click "Execute Action" to test ReactiveActions API...';
    },
    
    setupKeyboardHandlers: function() {
      const actionNameInput = document.getElementById('actionName');
      const actionDataInput = document.getElementById('actionData');
      
      if (actionNameInput) {
        actionNameInput.addEventListener('keypress', function(e) {
          if (e.key === 'Enter') {
            ReactiveActionsApiTesting.executeAction();
          }// API Testing functions
async function executeAction() {
  const actionName = document.getElementById('actionName').value.trim();
  const actionDataInput = document.getElementById('actionData').value.trim();
  const httpMethod = document.getElementById('httpMethod').value;
  const resultElement = document.getElementById('result');
  
  // Validate action name
  if (!actionName) {
    resultElement.textContent = 'Error: Action name is required';
    return;
  }
  
  // Parse JSON data
  let actionData = {};
  if (actionDataInput) {
    try {
      actionData = JSON.parse(actionDataInput);
    } catch (error) {
      resultElement.textContent = `Error: Invalid JSON data - ${error.message}`;
      return;
    }
  }
  
  resultElement.textContent = `Executing action "${actionName}" using ${httpMethod.toUpperCase()}...`;
  
  try {
    const startTime = performance.now();
    let response;
    
    // Use the selected HTTP method
    switch (httpMethod) {
      case 'get':
        response = await ReactiveActions.get(actionName, actionData);
        break;
      case 'post':
        response = await ReactiveActions.post(actionName, actionData);
        break;
      case 'put':
        response = await ReactiveActions.put(actionName, actionData);
        break;
      case 'patch':
        response = await ReactiveActions.patch(actionName, actionData);
        break;
      case 'delete':
        response = await ReactiveActions.delete(actionName, actionData);
        break;
      default:
        response = await ReactiveActions.execute(actionName, actionData);
        break;
    }
    
    const endTime = performance.now();
    
    resultElement.textContent = JSON.stringify({
      success: true,
      httpMethod: httpMethod.toUpperCase(),
      actionName: actionName,
      params: actionData,
      response: response,
      executionTime: `${(endTime - startTime).toFixed(2)}ms`,
      loadedVia: 'Turbo Frame'
    }, null, 2);
  } catch (error) {
    resultElement.textContent = JSON.stringify({
      success: false,
      httpMethod: httpMethod.toUpperCase(),
      actionName: actionName,
      params: actionData,
      error: error.message,
      stack: error.stack,
      loadedVia: 'Turbo Frame'
    }, null, 2);
  }
}

function clearApiLog() {
  document.getElementById('result').textContent = 'Click "Execute Action" to test ReactiveActions API...';
}

// Allow Enter key to execute action
document.addEventListener('DOMContentLoaded', function() {
  const actionNameInput = document.getElementById('actionName');
  const actionDataInput = document.getElementById('actionData');
  
  if (actionNameInput) {
    actionNameInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter') {
        executeAction();
      }
    });
  }
  
  if (actionDataInput) {
    actionDataInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter' && e.ctrlKey) {
        executeAction();
      }
    });
  }
});

// Also run when loaded via Turbo
document.addEventListener('turbo:frame-load', function(event) {
  if (event.target.id === 'test_content') {
    const actionNameInput = document.getElementById('actionName');
    const actionDataInput = document.getElementById('actionData');
    
    if (actionNameInput) {
      actionNameInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
          executeAction();
        }
      });
    }
    
    if (actionDataInput) {
      actionDataInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter' && e.ctrlKey) {
          executeAction();
        }
      });
    }
  }
});
        });
      }
      
      if (actionDataInput) {
        actionDataInput.addEventListener('keypress', function(e) {
          if (e.key === 'Enter' && e.ctrlKey) {
            ReactiveActionsApiTesting.executeAction();
          }
        });
      }
    },
    
    initializeApiTesting: function() {
      // Set up keyboard handlers for this content
      this.setupKeyboardHandlers();
      
      console.log('ReactiveActions API Testing: Initialized for content load', {
        timestamp: new Date().toISOString(),
        executionCount: (window.ReactiveActionsApiTestingExecutions || 0) + 1
      });
      
      // Track execution count
      window.ReactiveActionsApiTestingExecutions = (window.ReactiveActionsApiTestingExecutions || 0) + 1;
    }
  };
  
  // Set up event listeners only once
  if (!window.ReactiveActionsApiTestingListenersAdded) {
    // Use delegated event listeners instead of direct ones to avoid duplicates
    document.addEventListener('DOMContentLoaded', function() {
      ReactiveActionsApiTesting.initializeApiTesting();
    });
    
    // Handle Turbo frame loads
    document.addEventListener('turbo:frame-load', function(event) {
      if (event.target.id === 'test_content') {
        ReactiveActionsApiTesting.initializeApiTesting();
      }
    });
    
    window.ReactiveActionsApiTestingListenersAdded = true;
  }
  
  // Run initialization immediately if DOM is already loaded
  if (document.readyState === 'loading') {
    // DOM is still loading
  } else {
    // DOM is already loaded
    ReactiveActionsApiTesting.initializeApiTesting();
  }
  
  // Mark as initialized to prevent re-execution
  window.ReactiveActionsApiTestingInitialized = true;
  
})();