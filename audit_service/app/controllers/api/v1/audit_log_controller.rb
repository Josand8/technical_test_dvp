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
                              .order(created_at: :desc)

    if @audit_logs.any?
      render json: {
        success: true,
        data: @audit_logs.as_json
      }, status: :ok
    else
      render json: {
        success: false,
        message: "No se encontraron logs para la resource con id #{params[:resource_id]}"
      }, status: :not_found
    end
  end

  def show_invoice
    @audit_logs = AuditLog.where(resource_type: 'invoice', resource_id: params[:factura_id])
                              .order(created_at: :desc)

    if @audit_logs.any?
      stats = calculate_stats(@audit_logs)
      
      render json: {
        success: true,
        data: {
          factura_id: params[:factura_id],
          total_eventos: @audit_logs.count,
          estadisticas: stats,
          eventos: @audit_logs.as_json
        }
      }, status: :ok
    else
      render json: {
        success: false,
        message: "No se encontraron logs de auditoría para la factura #{params[:factura_id]}"
      }, status: :not_found
    end
  end

  def show_client
    @audit_logs = AuditLog.where(resource_type: 'client', resource_id: params[:cliente_id])
                              .order(created_at: :desc)

    if @audit_logs.any?
      stats = calculate_stats(@audit_logs)
      
      render json: {
        success: true,
        data: {
          cliente_id: params[:cliente_id],
          total_eventos: @audit_logs.count,
          estadisticas: stats,
          eventos: @audit_logs.as_json
        }
      }, status: :ok
    else
      render json: {
        success: false,
        message: "No se encontraron logs de auditoría para el cliente #{params[:cliente_id]}"
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
    params.require(:audit_log).permit(:resource_type, :resource_id, :action, :changes_made, :status, :error_message)
  end

  def calculate_stats(audit_logs)
    {
      total: audit_logs.count,
      por_accion: audit_logs.group_by(&:action).transform_values(&:count),
      por_estado: audit_logs.group_by(&:status).transform_values(&:count),
      primer_evento: audit_logs.last&.created_at,
      ultimo_evento: audit_logs.first&.created_at
    }
  end
end