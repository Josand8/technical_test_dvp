class Api::V1::InvoicesController < Api::V1::ApplicationController
  before_action :set_invoice, only: [:show]

  def index
    @invoices = Invoice.all

    if params[:client_id].present?
      @invoices = @invoices.by_client(params[:client_id])
    end

    if params[:status].present?
      @invoices = @invoices.where(status: params[:status])
    end

    if params[:fechaInicio].present? && params[:fechaFin].present?
      begin
        fecha_inicio = Date.parse(params[:fechaInicio])
        fecha_fin = Date.parse(params[:fechaFin])
        @invoices = @invoices.where(issue_date: fecha_inicio..fecha_fin)
      rescue ArgumentError
        return render json: {
          success: false,
          message: "Formato de fecha inválido. Use formato YYYY-MM-DD"
        }, status: :bad_request
      end
    elsif params[:fechaInicio].present?
      begin
        fecha_inicio = Date.parse(params[:fechaInicio])
        @invoices = @invoices.where("issue_date >= ?", fecha_inicio)
      rescue ArgumentError
        return render json: {
          success: false,
          message: "Formato de fecha inválido. Use formato YYYY-MM-DD"
        }, status: :bad_request
      end
    elsif params[:fechaFin].present?
      begin
        fecha_fin = Date.parse(params[:fechaFin])
        @invoices = @invoices.where("issue_date <= ?", fecha_fin)
      rescue ArgumentError
        return render json: {
          success: false,
          message: "Formato de fecha inválido. Use formato YYYY-MM-DD"
        }, status: :bad_request
      end
    end

    @invoices = @invoices.order(created_at: :desc)
    total_count = @invoices.count

    invoices_data = @invoices.map do |invoice|
      check_and_update_overdue(invoice)
      invoice_json = invoice.as_json(except: [:updated_at])
      client_data = ClientsService.find_client(invoice.client_id)
      
      if client_data
        invoice_json['client'] = {
          'id' => client_data['id'],
          'name' => client_data['name'],
          'email' => client_data['email']
        }
      end
      
      invoice_json
    end

    render json: {
      success: true,
      data: invoices_data,
      total_invoices: total_count
    }, status: :ok
  end

  def show
    check_and_update_overdue(@invoice)
    invoice_json = @invoice.as_json(except: [:updated_at])
    
    client_data = ClientsService.find_client(@invoice.client_id)
    
    if client_data
      invoice_json['client'] = {
        'id' => client_data['id'],
        'name' => client_data['name'],
        'email' => client_data['email'],
        'identification' => client_data['identification'],
        'address' => client_data['address']
      }
    end

    render json: {
      success: true,
      data: invoice_json
    }, status: :ok
  end

  def create
    @invoice = Invoice.new(invoice_params)

    if @invoice.save
      invoice_json = @invoice.as_json(except: [:updated_at])
      
      client_data = ClientsService.find_client(@invoice.client_id)
      
      if client_data
        invoice_json['client'] = {
          'id' => client_data['id'],
          'name' => client_data['name'],
          'email' => client_data['email']
        }
      end

      render json: {
        success: true,
        message: "Factura creada exitosamente",
        data: invoice_json
      }, status: :created
    else
      render json: {
        success: false,
        message: "No se pudo crear la factura",
        errors: @invoice.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_invoice
    @invoice = Invoice.find_by(id: params[:id])
    
    unless @invoice
      render json: {
        success: false,
        message: "Factura no encontrada"
      }, status: :not_found
    end
  end

  def check_and_update_overdue(invoice)
    return unless invoice.due_date.present?
    return unless invoice.status == 'pending'
    
    if Date.current > invoice.due_date
      invoice.update_column(:status, 'overdue')
    end
  end

  def invoice_params
    params.require(:invoice).permit(
      :client_id,
      :invoice_number,
      :issue_date,
      :due_date,
      :subtotal,
      :tax,
      :status,
      :notes
    )
  end
end

