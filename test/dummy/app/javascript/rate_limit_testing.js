(function() {
  'use strict';
  
  // Prevent multiple execution
  if (window.RateLimitTestingInitialized) {
    console.log('Rate Limit Testing: Already initialized, skipping script execution');
    return;
  }
  
  // Rate Limit Testing namespace
  window.RateLimitTesting = {
    testConfig: {
      enabled: true,
      globalEnabled: false,
      limit: 5,
      window: 60,
      key: 'test_user'
    },
    
    statusRefreshInterval: null,
    
    // Apply configuration changes
    applyConfiguration: function() {
      this.testConfig = {
        enabled: document.getElementById('rateLimitEnabled').checked,
        globalEnabled: document.getElementById('globalRateLimitEnabled').checked,
        limit: parseInt(document.getElementById('testLimit').value) || 5,
        window: parseInt(document.getElementById('testWindow').value) || 60,
        key: document.getElementById('testKey').value || 'test_user'
      };
      
      this.logResult('🔧 Configuration applied', this.testConfig);
      
      // Set up auto-refresh if enabled
      const autoRefresh = document.getElementById('autoRefreshStatus');
      if (autoRefresh && autoRefresh.checked) {
        this.startStatusRefresh();
      } else {
        this.stopStatusRefresh();
      }
    },
    
    // Test basic rate limiting
    testRateLimit: async function() {
      this.logResult('🧪 Testing basic rate limit...', { key: this.testConfig.key });
      
      try {
        const response = await this.callRateLimitAction('rate_limit_test', {
          test_type: 'basic',
          key: this.testConfig.key,
          limit: this.testConfig.limit,
          window: this.testConfig.window,
          enabled: this.testConfig.enabled
        });
        
        this.logResult('✅ Basic rate limit test completed', response);
        this.updateCurrentStatus();
        
      } catch (error) {
        this.logResult('❌ Basic rate limit test failed', { 
          error: error.message,
          type: this.getErrorType(error.message)
        });
      }
    },
    
    // Test rate limiting with custom cost
    testRateLimitWithCost: async function() {
      const cost = 3;
      this.logResult(`🧪 Testing rate limit with cost ${cost}...`, { 
        key: this.testConfig.key,
        cost: cost
      });
      
      try {
        const response = await this.callRateLimitAction('rate_limit_test', {
          test_type: 'cost',
          key: this.testConfig.key,
          limit: this.testConfig.limit,
          window: this.testConfig.window,
          cost: cost,
          enabled: this.testConfig.enabled
        });
        
        this.logResult('✅ Cost-based rate limit test completed', response);
        this.updateCurrentStatus();
        
      } catch (error) {
        this.logResult('❌ Cost-based rate limit test failed', { 
          error: error.message,
          cost: cost
        });
      }
    },
    
    // Test multiple rapid requests
    testMultipleRequests: async function() {
      const requestCount = this.testConfig.limit + 2;
      this.logResult(`🧪 Testing ${requestCount} rapid requests...`, { 
        requests: requestCount,
        limit: this.testConfig.limit
      });
      
      const results = [];
      
      for (let i = 1; i <= requestCount; i++) {
        try {
          const response = await this.callRateLimitAction('rate_limit_test', {
            test_type: 'multiple',
            key: this.testConfig.key,
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            request_number: i,
            enabled: this.testConfig.enabled
          });
          
          results.push({ request: i, success: true, response: response });
          
        } catch (error) {
          results.push({ 
            request: i, 
            success: false, 
            error: error.message,
            type: this.getErrorType(error.message),
            isRateLimitError: this.isRateLimitError(error)
          });
        }
        
        // Small delay between requests
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      const successful = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      const rateLimited = results.filter(r => !r.success && r.isRateLimitError).length;
      
      this.logResult('📊 Multiple requests test completed', {
        total: requestCount,
        successful: successful,
        failed: failed,
        rateLimited: rateLimited,
        limit: this.testConfig.limit,
        results: results
      });
      
      this.updateCurrentStatus();
    },
    
    // Test that rate limiting is properly triggered
    testRateLimitTriggering: async function() {
      this.logResult('🎯 Testing rate limit triggering...', { 
        limit: this.testConfig.limit 
      });
      
      const testKey = `trigger_test_${Date.now()}`;
      let successCount = 0;
      let rateLimitCount = 0;
      let otherErrorCount = 0;
      
      try {
        // Fill up to the exact limit
        for (let i = 1; i <= this.testConfig.limit; i++) {
          const response = await this.callRateLimitAction('rate_limit_test', {
            test_type: 'trigger_test',
            key: testKey,
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            enabled: this.testConfig.enabled
          });
          
          if (response.success) {
            successCount++;
            this.logResult(`✅ Request ${i}/${this.testConfig.limit} succeeded`, {
              remaining: this.testConfig.limit - i
            });
          }
        }
        
        // Now test requests that SHOULD be rate limited
        const extraRequests = 3;
        for (let i = 1; i <= extraRequests; i++) {
          try {
            const response = await this.callRateLimitAction('rate_limit_test', {
              test_type: 'should_fail',
              key: testKey,
              limit: this.testConfig.limit,
              window: this.testConfig.window,
              enabled: this.testConfig.enabled
            });
            
            // This should NOT succeed
            this.logResult(`❌ UNEXPECTED: Request ${this.testConfig.limit + i} succeeded when it should have been rate limited!`, response);
            
          } catch (error) {
            if (this.isRateLimitError(error)) {
              rateLimitCount++;
              this.logResult(`✅ EXPECTED: Request ${this.testConfig.limit + i} properly rate limited`, {
                error: error.message,
                type: 'Rate Limit Exceeded'
              });
            } else {
              otherErrorCount++;
              this.logResult(`❌ UNEXPECTED ERROR: Request ${this.testConfig.limit + i} failed with non-rate-limit error`, {
                error: error.message,
                type: this.getErrorType(error.message)
              });
            }
          }
        }
        
        // Verify results
        const expectedSuccess = this.testConfig.limit;
        const expectedRateLimit = extraRequests;
        
        const testPassed = successCount === expectedSuccess && 
                          rateLimitCount === expectedRateLimit && 
                          otherErrorCount === 0;
        
        this.logResult(testPassed ? '✅ Rate limit triggering test PASSED' : '❌ Rate limit triggering test FAILED', {
          expected: {
            successful: expectedSuccess,
            rateLimited: expectedRateLimit,
            otherErrors: 0
          },
          actual: {
            successful: successCount,
            rateLimited: rateLimitCount,
            otherErrors: otherErrorCount
          },
          testPassed: testPassed
        });
        
        return testPassed;
        
      } catch (error) {
        this.logResult('❌ Rate limit triggering test failed with unexpected error', {
          error: error.message
        });
        return false;
      }
    },
    
    // Test that rate limiting is NOT triggered when it shouldn't be
    testRateLimitNotTriggering: async function() {
      this.logResult('🎯 Testing rate limit NOT triggering...', { 
        requests: this.testConfig.limit - 1 
      });
      
      const testKey = `no_trigger_test_${Date.now()}`;
      let successCount = 0;
      let errorCount = 0;
      
      try {
        // Make requests just under the limit
        const requestsToMake = Math.max(1, this.testConfig.limit - 1);
        
        for (let i = 1; i <= requestsToMake; i++) {
          try {
            const response = await this.callRateLimitAction('rate_limit_test', {
              test_type: 'should_succeed',
              key: testKey,
              limit: this.testConfig.limit,
              window: this.testConfig.window,
              enabled: this.testConfig.enabled
            });
            
            if (response.success) {
              successCount++;
              this.logResult(`✅ Request ${i}/${requestsToMake} succeeded as expected`, {
                remaining: this.testConfig.limit - i
              });
            } else {
              errorCount++;
              this.logResult(`❌ UNEXPECTED: Request ${i} failed when it should have succeeded`, response);
            }
            
          } catch (error) {
            errorCount++;
            const isRateLimit = this.isRateLimitError(error);
            this.logResult(`❌ UNEXPECTED: Request ${i} failed${isRateLimit ? ' with rate limit error' : ''} when it should have succeeded`, {
              error: error.message,
              type: this.getErrorType(error.message),
              isRateLimitError: isRateLimit
            });
          }
        }
        
        const testPassed = successCount === requestsToMake && errorCount === 0;
        
        this.logResult(testPassed ? '✅ Rate limit NOT triggering test PASSED' : '❌ Rate limit NOT triggering test FAILED', {
          expected: {
            successful: requestsToMake,
            errors: 0
          },
          actual: {
            successful: successCount,
            errors: errorCount
          },
          testPassed: testPassed
        });
        
        return testPassed;
        
      } catch (error) {
        this.logResult('❌ Rate limit NOT triggering test failed with unexpected error', {
          error: error.message
        });
        return false;
      }
    },
    
    // Test disabled rate limiting (should never trigger)
    testDisabledRateLimitingVerification: async function() {
      this.logResult('🚫 Testing disabled rate limiting verification...', {});
      
      const testKey = `disabled_test_${Date.now()}`;
      const requestsToMake = this.testConfig.limit * 2; // Way over normal limit
      let successCount = 0;
      let errorCount = 0;
      
      try {
        for (let i = 1; i <= requestsToMake; i++) {
          try {
            const response = await this.callRateLimitAction('rate_limit_test', {
              test_type: 'disabled_verification',
              key: testKey,
              limit: 1, // Very low limit that would normally trigger
              window: this.testConfig.window,
              enabled: false // Explicitly disabled
            });
            
            if (response.success) {
              successCount++;
            } else {
              errorCount++;
              this.logResult(`❌ UNEXPECTED: Request ${i} failed when rate limiting is disabled`, response);
            }
            
          } catch (error) {
            errorCount++;
            const isRateLimit = this.isRateLimitError(error);
            this.logResult(`❌ UNEXPECTED: Request ${i} ${isRateLimit ? 'was rate limited' : 'failed'} when rate limiting is disabled`, {
              error: error.message,
              type: this.getErrorType(error.message),
              isRateLimitError: isRateLimit
            });
          }
        }
        
        const testPassed = successCount === requestsToMake && errorCount === 0;
        
        this.logResult(testPassed ? '✅ Disabled rate limiting verification PASSED' : '❌ Disabled rate limiting verification FAILED', {
          expected: {
            successful: requestsToMake,
            errors: 0,
            rateLimited: 0
          },
          actual: {
            successful: successCount,
            errors: errorCount
          },
          testPassed: testPassed
        });
        
        return testPassed;
        
      } catch (error) {
        this.logResult('❌ Disabled rate limiting verification failed with unexpected error', {
          error: error.message
        });
        return false;
      }
    },
    
    // Test rate limit reset functionality
    testRateLimitResetVerification: async function() {
      this.logResult('🔄 Testing rate limit reset verification...', {});
      
      const testKey = `reset_test_${Date.now()}`;
      let phase1Success = 0;
      let phase1RateLimit = 0;
      let phase2Success = 0;
      
      try {
        // Phase 1: Fill up the rate limit
        this.logResult('Phase 1: Filling up rate limit...', {});
        
        for (let i = 1; i <= this.testConfig.limit; i++) {
          try {
            await this.callRateLimitAction('rate_limit_test', {
              test_type: 'reset_phase1',
              key: testKey,
              limit: this.testConfig.limit,
              window: this.testConfig.window,
              enabled: this.testConfig.enabled
            });
            phase1Success++;
          } catch (error) {
            if (this.isRateLimitError(error)) {
              phase1RateLimit++;
              this.logResult(`❌ UNEXPECTED: Got rate limited during phase 1 at request ${i}`, {});
            }
          }
        }
        
        // Verify we can't make more requests
        try {
          await this.callRateLimitAction('rate_limit_test', {
            test_type: 'reset_verify_full',
            key: testKey,
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            enabled: this.testConfig.enabled
          });
          this.logResult('❌ UNEXPECTED: Request succeeded when rate limit should be full', {});
        } catch (error) {
          if (this.isRateLimitError(error)) {
            this.logResult('✅ EXPECTED: Rate limit properly triggered when full', {});
          } else {
            this.logResult('❌ UNEXPECTED: Got non-rate-limit error when testing full limit', {
              error: error.message
            });
          }
        }
        
        // Phase 2: Reset and test again
        this.logResult('Phase 2: Resetting rate limit...', {});
        
        await this.callRateLimitAction('rate_limit_reset', {
          key: testKey,
          window: this.testConfig.window,
          enabled: this.testConfig.enabled
        });
        
        // Now we should be able to make requests again
        try {
          const response = await this.callRateLimitAction('rate_limit_test', {
            test_type: 'reset_phase2',
            key: testKey,
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            enabled: this.testConfig.enabled
          });
          
          if (response.success) {
            phase2Success++;
            this.logResult('✅ EXPECTED: Request succeeded after reset', response);
          } else {
            this.logResult('❌ UNEXPECTED: Request failed after reset', response);
          }
          
        } catch (error) {
          this.logResult('❌ UNEXPECTED: Request failed after reset', {
            error: error.message,
            isRateLimitError: this.isRateLimitError(error)
          });
        }
        
        const testPassed = phase1Success === this.testConfig.limit && 
                          phase1RateLimit === 0 && 
                          phase2Success === 1;
        
        this.logResult(testPassed ? '✅ Rate limit reset verification PASSED' : '❌ Rate limit reset verification FAILED', {
          phase1: {
            expectedSuccess: this.testConfig.limit,
            actualSuccess: phase1Success,
            unexpectedRateLimit: phase1RateLimit
          },
          phase2: {
            expectedSuccess: 1,
            actualSuccess: phase2Success
          },
          testPassed: testPassed
        });
        
        return testPassed;
        
      } catch (error) {
        this.logResult('❌ Rate limit reset verification failed with unexpected error', {
          error: error.message
        });
        return false;
      }
    },
    
    // Check current rate limit status
    checkStatus: async function() {
      this.logResult('📊 Checking rate limit status...', { key: this.testConfig.key });
      
      try {
        const response = await this.callRateLimitAction('rate_limit_status', {
          key: this.testConfig.key,
          limit: this.testConfig.limit,
          window: this.testConfig.window,
          enabled: this.testConfig.enabled
        });
        
        this.logResult('📋 Rate limit status retrieved', response);
        this.updateCurrentStatus(response);
        
      } catch (error) {
        this.logResult('❌ Status check failed', { error: error.message });
      }
    },
    
    // Check if a request would exceed the limit
    checkWouldExceed: async function() {
      const cost = 3;
      this.logResult(`🔍 Checking if cost ${cost} would exceed limit...`, { 
        key: this.testConfig.key,
        cost: cost
      });
      
      try {
        const response = await this.callRateLimitAction('rate_limit_would_exceed', {
          key: this.testConfig.key,
          limit: this.testConfig.limit,
          window: this.testConfig.window,
          cost: cost,
          enabled: this.testConfig.enabled
        });
        
        this.logResult('🔍 Would exceed check completed', response);
        
      } catch (error) {
        this.logResult('❌ Would exceed check failed', { error: error.message });
      }
    },
    
    // Reset rate limit
    resetRateLimit: async function() {
      this.logResult('🔄 Resetting rate limit...', { key: this.testConfig.key });
      
      try {
        const response = await this.callRateLimitAction('rate_limit_reset', {
          key: this.testConfig.key,
          window: this.testConfig.window,
          enabled: this.testConfig.enabled
        });
        
        this.logResult('✅ Rate limit reset completed', response);
        this.updateCurrentStatus();
        
      } catch (error) {
        this.logResult('❌ Rate limit reset failed', { error: error.message });
      }
    },
    
    // Test different keys
    testDifferentKeys: async function() {
      const keys = ['user:1', 'user:2', 'api:endpoint'];
      this.logResult('🔑 Testing different keys...', { keys: keys });
      
      const results = {};
      
      for (const key of keys) {
        try {
          const response = await this.callRateLimitAction('rate_limit_test', {
            test_type: 'different_key',
            key: key,
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            enabled: this.testConfig.enabled
          });
          
          results[key] = { success: true, response: response };
          
        } catch (error) {
          results[key] = { success: false, error: error.message };
        }
        
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      this.logResult('🔑 Different keys test completed', results);
    },
    
    // Test scoped keys
    testScopedKeys: async function() {
      const scopes = ['api', 'search', 'upload'];
      this.logResult('🎯 Testing scoped keys...', { scopes: scopes });
      
      const results = {};
      
      for (const scope of scopes) {
        try {
          const response = await this.callRateLimitAction('rate_limit_scoped', {
            scope: scope,
            identifier: 'test_user',
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            enabled: this.testConfig.enabled
          });
          
          results[scope] = { success: true, response: response };
          
        } catch (error) {
          results[scope] = { success: false, error: error.message };
        }
        
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      this.logResult('🎯 Scoped keys test completed', results);
    },
    
    // Test user-based keys
    testUserKeys: async function() {
      const users = [
        { id: 1, name: 'User One' },
        { id: 2, name: 'User Two' },
        { id: 3, name: 'User Three' }
      ];
      
      this.logResult('👥 Testing user-based keys...', { users: users });
      
      const results = {};
      
      for (const user of users) {
        try {
          const response = await this.callRateLimitAction('rate_limit_test', {
            test_type: 'user_based',
            user_id: user.id,
            user_name: user.name,
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            enabled: this.testConfig.enabled
          });
          
          results[`user_${user.id}`] = { success: true, response: response };
          
        } catch (error) {
          results[`user_${user.id}`] = { success: false, error: error.message };
        }
        
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      this.logResult('👥 User-based keys test completed', results);
    },
    
    // Test disabled rate limiting
    testDisabledRateLimiting: async function() {
      this.logResult('🚫 Testing disabled rate limiting...', {});
      
      try {
        const response = await this.callRateLimitAction('rate_limit_test', {
          test_type: 'disabled',
          key: this.testConfig.key,
          limit: 1, // Very low limit
          window: this.testConfig.window,
          enabled: false // Explicitly disabled
        });
        
        this.logResult('✅ Disabled rate limiting test completed', response);
        
      } catch (error) {
        this.logResult('❌ Disabled rate limiting test failed', { error: error.message });
      }
    },
    
    // Test rapid requests to trigger rate limiting
    testRapidRequests: async function() {
      const rapidCount = 10;
      this.logResult(`⚡ Testing ${rapidCount} rapid requests...`, { count: rapidCount });
      
      const promises = [];
      const startTime = performance.now();
      
      for (let i = 1; i <= rapidCount; i++) {
        promises.push(
          this.callRateLimitAction('rate_limit_test', {
            test_type: 'rapid',
            key: this.testConfig.key,
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            request_number: i,
            enabled: this.testConfig.enabled
          }).catch(error => ({ error: error.message, request: i, isRateLimitError: this.isRateLimitError(error) }))
        );
      }
      
      const results = await Promise.all(promises);
      const endTime = performance.now();
      
      const successful = results.filter(r => !r.error).length;
      const failed = results.filter(r => r.error).length;
      const rateLimited = results.filter(r => r.error && r.isRateLimitError).length;
      
      this.logResult('⚡ Rapid requests test completed', {
        total: rapidCount,
        successful: successful,
        failed: failed,
        rateLimited: rateLimited,
        duration: `${(endTime - startTime).toFixed(2)}ms`,
        results: results
      });
      
      this.updateCurrentStatus();
    },
    
    // Test time window expiry
    testTimeWindowExpiry: async function() {
      this.logResult('⏰ Testing time window expiry...', { 
        window: this.testConfig.window + ' seconds'
      });
      
      try {
        // Fill up the rate limit
        for (let i = 0; i < this.testConfig.limit; i++) {
          await this.callRateLimitAction('rate_limit_test', {
            test_type: 'expiry_setup',
            key: 'expiry_test',
            limit: this.testConfig.limit,
            window: 3, // Short window for testing
            enabled: this.testConfig.enabled
          });
        }
        
        this.logResult('⏰ Rate limit filled, waiting for window expiry...', {
          window: '3 seconds'
        });
        
        // Wait for window to expire
        await new Promise(resolve => setTimeout(resolve, 4000));
        
        // Try again - should work
        const response = await this.callRateLimitAction('rate_limit_test', {
          test_type: 'expiry_test',
          key: 'expiry_test',
          limit: this.testConfig.limit,
          window: 3,
          enabled: this.testConfig.enabled
        });
        
        this.logResult('✅ Time window expiry test completed', response);
        
      } catch (error) {
        this.logResult('❌ Time window expiry test failed', { error: error.message });
      }
    },
    
    // Enhanced comprehensive test suite
    runComprehensiveTests: async function() {
      this.logResult('🚀 Starting comprehensive rate limiting verification suite...', {
        configuration: this.testConfig
      });
      
      const tests = [
        { name: 'Rate Limit Triggering', fn: () => this.testRateLimitTriggering() },
        { name: 'Rate Limit NOT Triggering', fn: () => this.testRateLimitNotTriggering() },
        { name: 'Disabled Rate Limiting', fn: () => this.testDisabledRateLimitingVerification() },
        { name: 'Rate Limit Reset', fn: () => this.testRateLimitResetVerification() },
        { name: 'Status Check', fn: () => this.checkStatus() },
        { name: 'Would Exceed Check', fn: () => this.checkWouldExceed() },
        { name: 'Different Keys', fn: () => this.testDifferentKeys() }
      ];
      
      let passed = 0;
      let failed = 0;
      const results = {};
      
      for (const test of tests) {
        try {
          this.logResult(`🧪 Running verification: ${test.name}`, {});
          const result = await test.fn();
          
          if (result === true) {
            passed++;
            results[test.name] = 'PASSED';
          } else if (result === false) {
            failed++;
            results[test.name] = 'FAILED';
          } else {
            // For tests that don't return boolean (legacy tests)
            passed++;
            results[test.name] = 'COMPLETED';
          }
          
          await new Promise(resolve => setTimeout(resolve, 1000)); // Delay between tests
          
        } catch (error) {
          failed++;
          results[test.name] = `FAILED: ${error.message}`;
          this.logResult(`❌ ${test.name} failed with error`, { error: error.message });
        }
      }
      
      this.logResult('📊 Comprehensive verification suite completed', {
        total: tests.length,
        passed: passed,
        failed: failed,
        successRate: `${((passed / tests.length) * 100).toFixed(1)}%`,
        results: results
      });
      
      return { passed, failed, total: tests.length, results };
    },
    
    // Run all basic tests (legacy method)
    runAllTests: async function() {
      this.logResult('🚀 Starting basic rate limiting test suite...', {
        configuration: this.testConfig
      });
      
      const tests = [
        { name: 'Basic Rate Limit', fn: () => this.testRateLimit() },
        { name: 'Custom Cost', fn: () => this.testRateLimitWithCost() },
        { name: 'Status Check', fn: () => this.checkStatus() },
        { name: 'Would Exceed Check', fn: () => this.checkWouldExceed() },
        { name: 'Different Keys', fn: () => this.testDifferentKeys() },
        { name: 'Scoped Keys', fn: () => this.testScopedKeys() },
        { name: 'User Keys', fn: () => this.testUserKeys() },
        { name: 'Disabled State', fn: () => this.testDisabledRateLimiting() },
        { name: 'Multiple Requests', fn: () => this.testMultipleRequests() },
        { name: 'Reset Test', fn: () => this.resetRateLimit() }
      ];
      
      let passed = 0;
      let failed = 0;
      
      for (const test of tests) {
        try {
          this.logResult(`🧪 Running: ${test.name}`, {});
          await test.fn();
          passed++;
          await new Promise(resolve => setTimeout(resolve, 500)); // Delay between tests
        } catch (error) {
          failed++;
          this.logResult(`❌ ${test.name} failed`, { error: error.message });
        }
      }
      
      this.logResult('📊 Basic test suite completed', {
        total: tests.length,
        passed: passed,
        failed: failed,
        successRate: `${((passed / tests.length) * 100).toFixed(1)}%`
      });
    },
    
    // Clear all results
    clearAllResults: function() {
      this.clearResults();
      this.clearCurrentStatus();
      this.logResult('🧹 All results cleared', {});
    },
    
    // Update current status display
    updateCurrentStatus: async function(statusData = null) {
      const statusElement = document.getElementById('currentStatus');
      if (!statusElement) return;
      
      try {
        let status;
        if (statusData) {
          status = statusData;
        } else {
          const response = await this.callRateLimitAction('rate_limit_status', {
            key: this.testConfig.key,
            limit: this.testConfig.limit,
            window: this.testConfig.window,
            enabled: this.testConfig.enabled
          });
          status = response;
        }
        
        const timestamp = new Date().toLocaleTimeString();
        statusElement.textContent = `[${timestamp}] Current Status:\n${JSON.stringify(status, null, 2)}`;
        
      } catch (error) {
        const timestamp = new Date().toLocaleTimeString();
        statusElement.textContent = `[${timestamp}] Status Error: ${error.message}`;
      }
    },
    
    // Clear current status
    clearCurrentStatus: function() {
      const statusElement = document.getElementById('currentStatus');
      if (statusElement) {
        statusElement.textContent = 'Click "Check Status" to view current rate limit information...';
      }
    },
    
    // Start auto-refreshing status
    startStatusRefresh: function() {
      this.stopStatusRefresh(); // Clear any existing interval
      this.statusRefreshInterval = setInterval(() => {
        this.updateCurrentStatus();
      }, 2000); // Refresh every 2 seconds
      
      this.logResult('🔄 Auto-refresh enabled', { interval: '2 seconds' });
    },
    
    // Stop auto-refreshing status
    stopStatusRefresh: function() {
      if (this.statusRefreshInterval) {
        clearInterval(this.statusRefreshInterval);
        this.statusRefreshInterval = null;
        this.logResult('⏹️ Auto-refresh disabled', {});
      }
    },
    
    // Helper method to call rate limit actions
    callRateLimitAction: async function(actionName, params) {
      if (!window.ReactiveActions) {
        throw new Error('ReactiveActions client not available');
      }
      
      const response = await window.ReactiveActions.execute(actionName, params);
      
      if (!response.success) {
        throw new Error(response.error?.message || 'Unknown error');
      }
      
      return response;
    },
    
    // Helper method to check if an error is specifically a rate limit error
    isRateLimitError: function(error) {
      const message = error.message || error.toString();
      return message.includes('Rate limit exceeded') || 
             message.includes('RATE_LIMIT_EXCEEDED') ||
             message.includes('rate limit') ||
             message.includes('too many requests');
    },
    
    // Get error type from error message
    getErrorType: function(errorMessage) {
      if (errorMessage.includes('Rate limit exceeded') || errorMessage.includes('RATE_LIMIT_EXCEEDED')) {
        return 'Rate Limit Exceeded';
      } else if (errorMessage.includes('not found') || errorMessage.includes('NOT_FOUND')) {
        return 'Action Not Found';
      } else if (errorMessage.includes('Invalid') || errorMessage.includes('INVALID')) {
        return 'Invalid Parameters';
      } else {
        return 'Unknown Error';
      }
    },
    
    // Log results to the display
    logResult: function(message, data = {}) {
      const logElement = document.getElementById('rateLimitResults');
      if (logElement) {
        const timestamp = new Date().toLocaleTimeString();
        const logEntry = `[${timestamp}] ${message}\n${JSON.stringify(data, null, 2)}\n${'='.repeat(60)}\n\n`;
        
        if (logElement.textContent === 'Rate limiting test results will appear here...') {
          logElement.textContent = logEntry;
        } else {
          logElement.textContent = logEntry + logElement.textContent;
        }
        
        // Scroll to top to see latest results
        logElement.scrollTop = 0;
      }
    },
    
    // Clear results
    clearResults: function() {
      const logElement = document.getElementById('rateLimitResults');
      if (logElement) {
        logElement.textContent = 'Rate limiting test results will appear here...';
      }
    },
    
    // Initialize rate limit testing
    initializeRateLimitTesting: function() {
      // Apply initial configuration
      this.applyConfiguration();
      
      // Set up auto-refresh checkbox listener
      const autoRefreshCheckbox = document.getElementById('autoRefreshStatus');
      if (autoRefreshCheckbox) {
        autoRefreshCheckbox.addEventListener('change', (e) => {
          if (e.target.checked) {
            this.startStatusRefresh();
          } else {
            this.stopStatusRefresh();
          }
        });
      }
      
      this.logResult('🔧 Rate Limit Testing initialized', {
        timestamp: new Date().toISOString(),
        configuration: this.testConfig
      });
    }
  };
  
  // Set up event listeners only once
  if (!window.RateLimitTestingListenersAdded) {
    document.addEventListener('DOMContentLoaded', function() {
      RateLimitTesting.initializeRateLimitTesting();
    });
    
    document.addEventListener('turbo:frame-load', function(event) {
      if (event.target.id === 'test_content') {
        RateLimitTesting.initializeRateLimitTesting();
      }
    });
    
    // Clean up intervals when leaving the page
    window.addEventListener('beforeunload', function() {
      RateLimitTesting.stopStatusRefresh();
    });
    
    window.RateLimitTestingListenersAdded = true;
  }
  
  // Run initialization immediately if DOM is already loaded
  if (document.readyState !== 'loading') {
    RateLimitTesting.initializeRateLimitTesting();
  }
  
  // Mark as initialized
  window.RateLimitTestingInitialized = true;
  
})();