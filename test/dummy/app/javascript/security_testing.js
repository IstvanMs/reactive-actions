(function() {
  'use strict';
  
  // Prevent multiple execution
  if (window.SecurityTestingInitialized) {
    console.log('Security Testing: Already initialized, skipping script execution');
    return;
  }
  
  // Mock user states for testing
  const USER_STATES = {
    guest: { current_user: null },
    user: { 
      current_user: { 
        id: 1, 
        name: 'Test User', 
        email: 'user@test.com', 
        admin: false,
        special_access: false 
      } 
    },
    admin: { 
      current_user: { 
        id: 2, 
        name: 'Admin User', 
        email: 'admin@test.com', 
        admin: true,
        special_access: true 
      } 
    },
    special: { 
      current_user: { 
        id: 3, 
        name: 'Special User', 
        email: 'special@test.com', 
        admin: false,
        special_access: true 
      } 
    }
  };
  
  // Security Testing namespace
  window.SecurityTesting = {
    currentUserState: 'guest',
    
    setUserState: function(state) {
      this.currentUserState = state;
      const stateDisplay = document.getElementById('currentUserState');
      if (stateDisplay) {
        const stateNames = {
          guest: 'Guest (Not Logged In)',
          user: 'Regular User (Test User)',
          admin: 'Admin User (Admin User)', 
          special: 'Special Access User (Special User)'
        };
        stateDisplay.textContent = `Current State: ${stateNames[state] || state}`;
      }
      
      this.logResult(`🔄 User state changed to: ${state}`, { 
        state: state,
        user: USER_STATES[state].current_user
      });
    },
    
    testAction: async function(actionType, params = {}) {
      const actionMap = {
        public: 'public',
        protected: 'protected', 
        admin: 'admin',
        conditional: 'conditional',
        lambda_security: 'lambda_security'
      };
      
      const actionName = actionMap[actionType];
      if (!actionName) {
        this.logResult(`❌ Unknown action type: ${actionType}`, { error: 'Invalid action type' });
        return;
      }
      
      // Add current user context to params
      const testParams = {
        ...params,
        _mock_user_state: this.currentUserState,
        _mock_user_data: USER_STATES[this.currentUserState]
      };
      
      this.logResult(`🧪 Testing ${actionType} action...`, { 
        action: actionName,
        params: params,
        userState: this.currentUserState
      });
      
      try {
        const startTime = performance.now();
        const response = await ReactiveActions.execute(actionName, testParams);
        const endTime = performance.now();
        
        // Check if the response contains a security error
        const hasSecurityError = response.error && 
          (response.error.type === 'SecurityCheckError' || 
           response.error.type === 'UnauthorizedError');
        
        if (hasSecurityError) {
          // This is actually a failed security check, treat as an error
          throw new Error(response.error.message);
        }
        
        this.logResult(`✅ ${actionType} action succeeded`, {
          action: actionName,
          userState: this.currentUserState,
          response: response,
          executionTime: `${(endTime - startTime).toFixed(2)}ms`
        });
        
      } catch (error) {
        this.logResult(`❌ ${actionType} action failed`, {
          action: actionName,
          userState: this.currentUserState,
          error: error.message,
          errorType: this.getErrorType(error.message)
        });
        
        // Re-throw the error so testAllActions can catch it
        throw error;
      }
    },
    
    testAllActions: async function() {
      this.logResult('🚀 Starting comprehensive security test suite...', {});
      
      const testCases = [
        // Public action should always work
        { action: 'public', state: 'guest', shouldPass: true },
        { action: 'public', state: 'user', shouldPass: true },
        { action: 'public', state: 'admin', shouldPass: true },
        
        // Protected action needs authentication
        { action: 'protected', state: 'guest', shouldPass: false },
        { action: 'protected', state: 'user', shouldPass: true },
        { action: 'protected', state: 'admin', shouldPass: true },
        
        // Admin action needs admin role
        { action: 'admin', state: 'guest', shouldPass: false },
        { action: 'admin', state: 'user', shouldPass: false },
        { action: 'admin', state: 'admin', shouldPass: true },
        
        // Conditional without special flag
        { action: 'conditional', state: 'user', params: { special: 'false' }, shouldPass: true },
        { action: 'conditional', state: 'admin', params: { special: 'false' }, shouldPass: true },
        
        // Conditional with special flag (needs special access)
        { action: 'conditional', state: 'user', params: { special: 'true' }, shouldPass: false },
        { action: 'conditional', state: 'special', params: { special: 'true' }, shouldPass: true },
        
        // Lambda security with ownership
        { action: 'lambda_security', state: 'user', params: { user_id: '1' }, shouldPass: true },
        { action: 'lambda_security', state: 'user', params: { user_id: '999' }, shouldPass: false },
      ];
      
      let passed = 0;
      let failed = 0;
      
      for (const testCase of testCases) {
        this.setUserState(testCase.state);
        await new Promise(resolve => setTimeout(resolve, 100)); // Small delay between tests
        
        try {
          await this.testAction(testCase.action, testCase.params || {});
          if (testCase.shouldPass) {
            passed++;
          } else {
            failed++;
            this.logResult(`⚠️  Expected failure but action passed`, testCase);
          }
        } catch (error) {
          if (!testCase.shouldPass) {
            passed++;
          } else {
            failed++;
            this.logResult(`⚠️  Expected success but action failed`, testCase);
          }
        }
      }
      
      this.logResult(`📊 Test suite completed`, {
        total: testCases.length,
        passed: passed,
        failed: failed,
        successRate: `${((passed / testCases.length) * 100).toFixed(1)}%`
      });
    },
    
    getErrorType: function(errorMessage) {
      if (errorMessage.includes('Authentication required') || errorMessage.includes('Please log in')) {
        return 'Authentication Error';
      } else if (errorMessage.includes('Admin access required')) {
        return 'Authorization Error';
      } else if (errorMessage.includes('Special access required')) {
        return 'Special Access Error';
      } else if (errorMessage.includes('Can only access your own data')) {
        return 'Ownership Error';
      } else {
        return 'Security Check Error';
      }
    },
    
    logResult: function(message, data = {}) {
      const logElement = document.getElementById('securityResults');
      if (logElement) {
        const timestamp = new Date().toLocaleTimeString();
        const logEntry = `[${timestamp}] ${message}\n${JSON.stringify(data, null, 2)}\n${'='.repeat(60)}\n\n`;
        
        if (logElement.textContent === 'Security test results will appear here...') {
          logElement.textContent = logEntry;
        } else {
          logElement.textContent = logEntry + logElement.textContent;
        }
        
        // Scroll to top to see latest results
        logElement.scrollTop = 0;
      }
    },
    
    clearResults: function() {
      const logElement = document.getElementById('securityResults');
      if (logElement) {
        logElement.textContent = 'Security test results will appear here...';
      }
    },
    
    initializeSecurityTesting: function() {
      this.logResult('🔒 Security Testing initialized', {
        timestamp: new Date().toISOString(),
        availableStates: Object.keys(USER_STATES),
        currentState: this.currentUserState
      });
    }
  };
  
  // Set up event listeners only once
  if (!window.SecurityTestingListenersAdded) {
    document.addEventListener('DOMContentLoaded', function() {
      SecurityTesting.initializeSecurityTesting();
    });
    
    document.addEventListener('turbo:frame-load', function(event) {
      if (event.target.id === 'test_content') {
        SecurityTesting.initializeSecurityTesting();
      }
    });
    
    window.SecurityTestingListenersAdded = true;
  }
  
  // Run initialization immediately if DOM is already loaded
  if (document.readyState !== 'loading') {
    SecurityTesting.initializeSecurityTesting();
  }
  
  // Mark as initialized
  window.SecurityTestingInitialized = true;
  
})();