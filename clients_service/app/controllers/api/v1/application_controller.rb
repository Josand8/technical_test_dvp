class Api::V1::ApplicationController < ActionController::API
  def health_check
    render json: { status: "Clients Service is running" }, status: :ok
  end
end
