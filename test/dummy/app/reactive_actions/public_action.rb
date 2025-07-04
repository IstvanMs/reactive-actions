class PublicAction < ReactiveActions::ReactiveAction
  skip_security_checks

  def action
    @result = {
      success: true,
      message: "This is a public action - no security checks",
      timestamp: Time.current
    }
  end

  def response
    render json: @result
  end
end