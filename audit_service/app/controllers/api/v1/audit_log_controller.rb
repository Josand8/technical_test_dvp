class Api::V1::AuditLogController < Api::V1::ApplicationController
  def index
    @audit_logs = AuditLog.all

    @audit_logs = @audit_logs.where(resource_type: params[:resource_type]) if params[:resource_type].present?
    @audit_logs = @audit_logs.where(resource_id: params[:resource_id]) if params[:resource_id].present?
    @audit_logs = @audit_logs.where(status: params[:status]) if params[:status].present?

    if params[:start_date].present? && params[:end_date].present?
      @audit_logs = @audit_logs.where(
        :created_at.gte => DateTime.parse(params[:start_date]),
        :created_at.lte => DateTime.parse(params[:end_date])
      )
    end

    @audit_logs = @audit_logs.order(created_at: :desc).limit(100)

    render json: {
      success: true,
      data: @audit_logs.as_json,
      total_audit_logs: @audit_logs.count
    }, status: :ok
  end

  def show
    @audit_logs = AuditLog.where(resource_id: params[:resource_id])
    
    @audit_logs = @audit_logs.where(resource_type: params[:resource_type]) if params[:resource_type].present?
    
    @audit_logs = @audit_logs.order(created_at: :desc)

    if @audit_logs.any?
      render json: {
        success: true,
        data: @audit_logs.as_json,
        total_audit_logs: @audit_logs.count
      }, status: :ok
    else
      render json: {
        success: false,
        message: "No se encontraron logs para el recurso #{params[:resource_type]} con id #{params[:resource_id]}"
      }, status: :not_found
    end
  end

  def create
    @audit_log = AuditLog.new(audit_log_params)

    if @audit_log.save
      render json: {
        success: true,
        message: "Log creado exitosamente",
        data: @audit_log.as_json
      }, status: :created
    else
      render json: {
        success: false,
        message: "No se pudo crear el log",
        errors: @audit_log.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def audit_log_params
    params.require(:audit_log).permit(:resource_type, :resource_id, :action, :status, :error_message, changes_made: {})
  end
end