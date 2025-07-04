class TestController < ApplicationController
  def index
  end

  def api_test
    render turbo_stream: turbo_stream.update(:test_content, partial: 'api_test')
  end

  def dom_test
    render turbo_stream: turbo_stream.update(:test_content, partial: 'dom_test')
  end

  def security_test
    render turbo_stream: turbo_stream.update(:test_content, partial: 'security_test')
  end

  def manual_test
    render turbo_stream: turbo_stream.update(:test_content, partial: 'manual_test')
  end

  def rate_limit_test
    render turbo_stream: turbo_stream.update(:test_content, partial: 'rate_limit_test')
  end
end