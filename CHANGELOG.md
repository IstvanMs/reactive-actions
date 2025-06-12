# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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