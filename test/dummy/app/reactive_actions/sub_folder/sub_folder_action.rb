class SubFolderAction < ReactiveActions::ReactiveAction
  def action
  end

  def response
    render json: { from_sub_folder: true }, status: :ok
  end
end