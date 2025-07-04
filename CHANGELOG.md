# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-alpha.3] - 2025-07-04

### Added
- **Security Checks System**: Comprehensive security filtering for actions
  - `security_check` class method for defining security filters
  - Support for method names, lambdas, and conditional execution
  - Conditional options: `:if`, `:unless`, `:only`, `:except`
  - `skip_security_checks` to bypass all security filters
  - Automatic error conversion to `SecurityCheckError`
- **Rate Limiting System**: Complete rate limiting functionality
  - Core `RateLimiter` class with cache-based storage
  - `RateLimiter` concern for actions with helper methods
  - Controller-level rate limiting with automatic headers
  - Configurable rate limiting with custom key generators
  - Support for custom costs and multiple time windows
  - Rate limit status checking and reset functionality
- **New Error Types**: Enhanced error handling
  - `SecurityCheckError` for failed security checks
  - `RateLimitExceededError` with detailed limit information
- **Enhanced Configuration**: Extended configuration options
  - Rate limiting enable/disable controls
  - Global rate limiting configuration
  - Custom key generators and cost calculators
  - Delegated methods and instance variables configuration
- **Testing Utilities**: Comprehensive testing tools
  - Interactive rate limiting test suite in dummy app
  - Security check verification tests
  - Mock user system for testing authentication
  - Rate limiting verification scenarios
- **Enhanced Generator**: Updated install generator
  - Interactive rate limiting configuration
  - Advanced security options setup
  - Improved error handling and validation

### Improved
- Error handling now distinguishes between different error types
- Controller integration with automatic rate limit headers
- Configuration system with helper methods for checking feature status
- Documentation with comprehensive examples for all new features

### Security
- Added security check system to prevent unauthorized action execution
- Rate limiting to prevent abuse and protect against DoS attacks
- Proper error handling to avoid information leakage

## [0.1.0-alpha.2] - 2025-06-12

### Added
- Enhanced JavaScript client with manual initialization support
- Improved DOM binding with mutation observer for dynamic content
- Better error handling and response processing in JavaScript client
- Comprehensive DOM testing utilities

### Improved
- JavaScript client now supports manual configuration and initialization
- Better separation between client class and global instance
- Better logging and debugging capabilities

## [0.1.0-alpha.1] - 2025-05-30

### Added
- Initial alpha release of ReactiveActions
- HTTP API endpoints for executing server-side actions
- JavaScript client with automatic CSRF token handling
- Rails 8 compatibility with Propshaft + Importmap support
- Interactive installation generator
- Built-in security measures and parameter sanitization
- Structured error handling with specific error types
- Support for all HTTP methods (GET, POST, PUT, PATCH, DELETE)
- Action autoloading and namespace management
- Comprehensive test suite and documentation

### Security
- Parameter sanitization to prevent code injection
- CSRF protection integration
- Input validation and length limits