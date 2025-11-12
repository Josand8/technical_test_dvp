require "test_helper"

class Api::V1::ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Client.delete_all
    @client = Client.create!(
      name: "Juan Pérez",
      identification: "12345678",
      email: "juanperez@gmail.com",
      address: "Carrera 7 #23-45, Bogotá"
    )
  end

  test "should get index" do
    get api_v1_clients_url, as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response["success"]
    assert_not_nil json_response["data"]
    assert_not_nil json_response["total_clients"]
    assert_equal 1, json_response["total_clients"]
  end

  test "should get index with search by name" do
    get api_v1_clients_url(search: "Juan"), as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response["success"]
    assert json_response["data"].any?
    assert_equal 1, json_response["total_clients"]
  end

  test "should get index with search by email" do
    get api_v1_clients_url(search: "juanperez"), as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response["success"]
    assert json_response["data"].any?
    assert_equal 1, json_response["total_clients"]
  end

  test "should get index with search that returns no results" do
    get api_v1_clients_url(search: "NoExiste"), as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response["success"]
    assert_empty json_response["data"]
    assert_equal 0, json_response["total_clients"]
  end

  test "should show client" do
    get api_v1_client_url(@client), as: :json
    assert_response :success
    
    json_response = JSON.parse(@response.body)
    assert json_response["success"]
    assert_equal @client.id, json_response["data"]["id"]
    assert_equal @client.name, json_response["data"]["name"]
  end

  test "should return not found for non-existent client" do
    get api_v1_client_url(id: 99999), as: :json
    assert_response :not_found
    
    json_response = JSON.parse(@response.body)
    assert_not json_response["success"]
    assert_equal "Cliente no encontrado", json_response["message"]
  end

  test "should create client" do
    assert_difference("Client.count") do
      post api_v1_clients_url, params: {
        client: {
          name: "Nuevo Cliente",
          identification: "87654321",
          email: "nuevo@example.com",
          address: "Calle Nueva 456"
        }
      }, as: :json
    end
    
    assert_response :created
    json_response = JSON.parse(@response.body)
    assert json_response["success"]
    assert_equal "Cliente creado exitosamente", json_response["message"]
    assert_equal "Nuevo Cliente", json_response["data"]["name"]
  end

  test "should not create client without name" do
    assert_no_difference("Client.count") do
      post api_v1_clients_url, params: {
        client: {
          email: "test@example.com"
        }
      }, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_not json_response["success"]
    assert_not_nil json_response["errors"]
  end

  test "should not create client without email" do
    assert_no_difference("Client.count") do
      post api_v1_clients_url, params: {
        client: {
          name: "Test Client"
        }
      }, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_not json_response["success"]
  end

  test "should not create client with invalid email format" do
    assert_no_difference("Client.count") do
      post api_v1_clients_url, params: {
        client: {
          name: "Test Client",
          email: "invalid_email"
        }
      }, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_not json_response["success"]
  end

  test "should not create client with duplicate email" do
    assert_no_difference("Client.count") do
      post api_v1_clients_url, params: {
        client: {
          name: "Duplicate Email Client",
          email: @client.email
        }
      }, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(@response.body)
    assert_not json_response["success"]
  end
end

