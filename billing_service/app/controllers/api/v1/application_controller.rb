class Api::V1::ApplicationController < ActionController::API
  def health_check
    render json: { status: "Billing Service is running" }, status: :ok
  end
end

