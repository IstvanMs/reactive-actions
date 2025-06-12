(function() {
  'use strict';
  
  // Prevent multiple execution by checking if already initialized
  if (window.ReactiveActionsDomTestingInitialized) {
    console.log('ReactiveActions DOM Testing: Already initialized, skipping script execution');
    return;
  }
  
  // Namespace for DOM testing functions to avoid global pollution
  window.ReactiveActionsDomTesting = window.ReactiveActionsDomTesting || {
    dynamicButtonCounter: 0,
    
    addDynamicButton: function() {
      this.dynamicButtonCounter++;
      const container = document.getElementById('dynamicContainer');
      
      if (container) {
        const button = document.createElement('button');
        button.textContent = `Dynamic Button ${this.dynamicButtonCounter} (Turbo)`;
        button.setAttribute('reactive-action', 'click->delete#test');
        button.setAttribute('reactive-action-dynamic-id', this.dynamicButtonCounter);
        button.setAttribute('reactive-action-source', 'dynamic_turbo');
        button.setAttribute('data-loading-text', 'Deleting...');
        button.style.cssText = 'background: #dc3545; color: white; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; margin: 5px;';
        
        container.appendChild(button);
        
        this.logDomEvent('Dynamic button added (Turbo)', { id: this.dynamicButtonCounter });
      }
    },
    
    clearDomLog: function() {
      const domResult = document.getElementById('domResult');
      if (domResult) {
        domResult.textContent = 'DOM binding events will appear here...';
      }
    },
    
    logDomEvent: function(event, data = {}) {
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
    },
    
    initializeDomTesting: function() {
      // Log that DOM content was loaded via Turbo
      this.logDomEvent('DOM Test content loaded via Turbo', {
        timestamp: new Date().toISOString(),
        buttonsCount: document.querySelectorAll('[reactive-action]').length,
        executionCount: (window.ReactiveActionsDomTestingExecutions || 0) + 1
      });
      
      // Track execution count
      window.ReactiveActionsDomTestingExecutions = (window.ReactiveActionsDomTestingExecutions || 0) + 1;
    }
  };
  
  // Set up event listeners only once
  if (!window.ReactiveActionsDomTestingListenersAdded) {
    // Use delegated event listeners instead of direct ones to avoid duplicates
    document.addEventListener('DOMContentLoaded', function() {
      ReactiveActionsDomTesting.initializeDomTesting();
    });
    
    // Handle Turbo frame loads
    document.addEventListener('turbo:frame-load', function(event) {
      if (event.target.id === 'test_content') {
        ReactiveActionsDomTesting.initializeDomTesting();
      }
    });
    
    // Handle Turbo stream actions (when content is updated via streams)
    document.addEventListener('turbo:before-stream-render', function(event) {
      console.log('ReactiveActions: Turbo stream about to render');
    });
    
    document.addEventListener('turbo:stream-render', function(event) {
      console.log('ReactiveActions: Turbo stream rendered');
      // Let ReactiveActions handle the new elements automatically
    });
    
    window.ReactiveActionsDomTestingListenersAdded = true;
  }
  
  // Run initialization immediately if DOM is already loaded
  if (document.readyState === 'loading') {
    // DOM is still loading
  } else {
    // DOM is already loaded
    ReactiveActionsDomTesting.initializeDomTesting();
  }
  
  // Mark as initialized to prevent re-execution
  window.ReactiveActionsDomTestingInitialized = true;
  
})();