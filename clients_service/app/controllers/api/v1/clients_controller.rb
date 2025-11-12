class Api::V1::ClientsController < Api::V1::ApplicationController
  before_action :set_client, only: [:show]

  def index
    @clients = Client.all

    if params[:search].present?
      search_term = params[:search]
      @clients = @clients.by_name(search_term).or(@clients.by_email(search_term))
    end


    render json: {
      success: true,
      data: @clients.as_json(except: [:updated_at]),
      total_clients: @clients.count
    }, status: :ok
  end

  def show
    render json: {
      success: true,
      data: @client.as_json(except: [:updated_at])
    }, status: :ok
  end

  def create
    @client = Client.new(client_params)

    if @client.save
      render json: {
        success: true,
        message: "Cliente creado exitosamente",
        data: @client.as_json(except: [:updated_at])
      }, status: :created
    else
      render json: {
        success: false,
        message: "No se pudo crear el cliente",
        errors: @client.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_client
    @client = Client.find_by(id: params[:id])
    
    unless @client
      render json: {
        success: false,
        message: "Cliente no encontrado"
      }, status: :not_found
    end
  end

  def client_params
    params.require(:client).permit(
      :name,
      :identification,
      :email,
      :address
    )
  end
end

