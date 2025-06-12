// Use the global ReactiveActionsClient class (exposed by application.js)
let reactiveActions = null;

// Configuration management - this initializes the client
function initializeClient(button) {
  const config = {
    baseUrl: document.getElementById('baseUrl').value,
    defaultHttpMethod: document.getElementById('defaultMethod').value,
    enableAutoBinding: document.getElementById('enableAutoBinding').checked,
    enableMutationObserver: document.getElementById('enableMutationObserver').checked
  };
  
  // Create new instance with config and initialize
  reactiveActions = new window.ReactiveActionsClient();
  reactiveActions.configure(config).initialize();
  
  // Make available globally for other test scripts
  window.ReactiveActions = reactiveActions;
  
  // Update button text to show it's initialized
  button.textContent = 'Client Initialized ✓';
  button.style.backgroundColor = '#28a745';
  button.disabled = true;
  
  // Add reinitialize button
  if (!document.getElementById('reinitializeBtn')) {
    const reinitBtn = document.createElement('button');
    reinitBtn.id = 'reinitializeBtn';
    reinitBtn.textContent = 'Reinitialize with New Config';
    reinitBtn.style.cssText = 'background: #ffc107; color: #212529; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; margin-left: 10px;';
    reinitBtn.onclick = () => reinitializeClient(button, reinitBtn);
    button.parentNode.appendChild(reinitBtn);
  }
  
  updateStatusIndicator(true);
  logDomEvent('Client initialized', config);
}

function reinitializeClient(originalBtn, reinitBtn) {
  // Reset the original button
  originalBtn.textContent = 'Initialize Client';
  originalBtn.style.backgroundColor = '#007cba';
  originalBtn.disabled = false;
  
  // Remove the reinitialize button
  reinitBtn.remove();
  
  // Clear the current instance
  reactiveActions = null;
  window.ReactiveActions = null;
  
  updateStatusIndicator(false);
  logDomEvent('Client reset', {});
}

function updateStatusIndicator(isLoaded) {
  const indicator = document.getElementById('statusIndicator');
  if (indicator) {
    if (isLoaded) {
      indicator.innerHTML = '✅ ReactiveActionsClient Initialized';
      indicator.style.backgroundColor = '#d4edda';
      indicator.style.color = '#155724';
      indicator.style.border = '1px solid #c3e6cb';
    } else {
      indicator.innerHTML = '⏳ Ready to Initialize';
      indicator.style.backgroundColor = '#fff3cd';
      indicator.style.color = '#856404';
      indicator.style.border = '1px solid #ffeaa7';
    }
  }
}

function logDomEvent(event, data = {}) {
  const logElement = document.getElementById('domResult');
  if (logElement) {
    const timestamp = new Date().toLocaleTimeString();
    const logEntry = `[${timestamp}] ${event}: ${JSON.stringify(data, null, 2)}\n\n`;
    
    if (logElement.textContent === 'DOM binding events will appear here...') {
      logElement.textContent = logEntry;
    } else {
      logElement.textContent = logEntry + logElement.textContent;
    }
  }
}

// Tab switching functionality for Turbo
document.addEventListener('turbo:frame-load', function(event) {
  // Update tab appearance when content loads
  if (event.target.id === 'test_content') {
    updateTabAppearance();
    
    // Reinitialize ReactiveActions for new content
    if (reactiveActions) {
      reactiveActions.initialized = false;
      reactiveActions.boundElements = new WeakSet();
      reactiveActions.initialize();
    }
  }
});

function updateTabAppearance() {
  const currentPath = window.location.pathname;
  document.querySelectorAll('.tab-button').forEach(button => {
    button.style.borderBottomColor = 'transparent';
    button.style.color = 'inherit';
  });
  
  if (currentPath.includes('/api') || currentPath === '/' || currentPath === '/test') {
    const apiTab = document.getElementById('tab-api');
    if (apiTab) {
      apiTab.style.borderBottomColor = '#007cba';
      apiTab.style.color = '#007cba';
    }
  } else if (currentPath.includes('/dom')) {
    const domTab = document.getElementById('tab-dom');
    if (domTab) {
      domTab.style.borderBottomColor = '#007cba';
      domTab.style.color = '#007cba';
    }
  }
}

// Event listeners for DOM binding events
document.addEventListener('reactive-action:success', function(event) {
  logDomEvent('Action Success', {
    element: event.detail.element.tagName,
    response: event.detail.response
  });
});

document.addEventListener('reactive-action:error', function(event) {
  logDomEvent('Action Error', {
    element: event.detail.element.tagName,
    error: event.detail.error.message
  });
});

// Initialize when DOM is loaded and when Turbo loads
function checkReactiveActionsAvailability() {
  if (typeof window.ReactiveActionsClient !== 'undefined') {
    console.log('✅ ReactiveActionsClient class is available:', window.ReactiveActionsClient);
    updateStatusIndicator(false); // Ready to initialize, but not initialized yet
  } else {
    console.error('❌ ReactiveActionsClient class is not available');
    const indicator = document.getElementById('statusIndicator');
    if (indicator) {
      indicator.innerHTML = '❌ ReactiveActionsClient Not Available';
      indicator.style.backgroundColor = '#f8d7da';
      indicator.style.color = '#721c24';
      indicator.style.border = '1px solid #f5c6cb';
    }
  }
}

// Make functions globally available (remove the window assignments at the bottom)
window.updateConfiguration = updateConfiguration;
window.active_tab = active_tab;

function active_tab(tab) {
  document.querySelectorAll('a.tab-button.active').forEach(element => {
    element.classList.remove('active');
  });
  tab.classList.add('active');
}

document.addEventListener('DOMContentLoaded', initializeReactiveActions);
document.addEventListener('turbo:frame-load', initializeReactiveActions);