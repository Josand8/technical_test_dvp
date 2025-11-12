require "test_helper"

class Api::V1::InvoicesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @invoice = invoices(:one)
    
    # Mock data para clientes
    @client_data = {
      'id' => 1,
      'name' => 'Cliente Test',
      'email' => 'test@example.com',
      'identification' => '12345678',
      'address' => 'Dirección Test'
    }
    
    @client_data_2 = {
      'id' => 2,
      'name' => 'Cliente Test 2',
      'email' => 'test2@example.com',
      'identification' => '87654321',
      'address' => 'Dirección Test 2'
    }
  end

  # ==================== PRUEBAS DE INDEX ====================

  test "should get index" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas"
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert json_response['success']
      assert_not_nil json_response['data']
      assert_not_nil json_response['total_invoices']
      assert_equal 4, json_response['total_invoices']
    end
  end

  test "index should include client data in response" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas"
      assert_response :success
      
      json_response = JSON.parse(response.body)
      first_invoice = json_response['data'].first
      
      assert_not_nil first_invoice['client']
      assert_equal @client_data['id'], first_invoice['client']['id']
      assert_equal @client_data['name'], first_invoice['client']['name']
      assert_equal @client_data['email'], first_invoice['client']['email']
    end
  end

  test "index should filter by client_id" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas", params: { client_id: 1 }
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert json_response['success']
      assert_equal 2, json_response['total_invoices']
      
      json_response['data'].each do |invoice|
        assert_equal 1, invoice['client_id']
      end
    end
  end

  test "index should return not_found for non-existent client" do
    ClientsService.stub(:find_client, nil) do
      get "/api/v1/facturas", params: { client_id: 999 }
      assert_response :not_found
      
      json_response = JSON.parse(response.body)
      assert_not json_response['success']
      assert_equal "Cliente no encontrado", json_response['message']
    end
  end

  test "index should filter by invoice_number" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas", params: { invoice_number: "INV-20251112-0001" }
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert_equal 1, json_response['total_invoices']
      assert_equal "INV-20251112-0001", json_response['data'].first['invoice_number']
    end
  end

  test "index should filter by status" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas", params: { status: "paid" }
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert_equal 1, json_response['total_invoices']
      
      json_response['data'].each do |invoice|
        assert_equal "paid", invoice['status']
      end
    end
  end

  test "index should filter by date range" do
    ClientsService.stub(:find_client, @client_data) do
      fecha_inicio = (Date.current - 1.day).to_s
      fecha_fin = (Date.current + 1.day).to_s
      
      get "/api/v1/facturas", params: { fechaInicio: fecha_inicio, fechaFin: fecha_fin }
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert json_response['success']
    end
  end

  test "index should filter by fechaInicio only" do
    ClientsService.stub(:find_client, @client_data) do
      fecha_inicio = Date.current.to_s
      
      get "/api/v1/facturas", params: { fechaInicio: fecha_inicio }
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert json_response['success']
    end
  end

  test "index should filter by fechaFin only" do
    ClientsService.stub(:find_client, @client_data) do
      fecha_fin = (Date.current + 5.days).to_s
      
      get "/api/v1/facturas", params: { fechaFin: fecha_fin }
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert json_response['success']
    end
  end

  test "index should return bad_request for invalid date format" do
    get "/api/v1/facturas", params: { fechaInicio: "invalid-date" }
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal "Formato de fecha inválido. Use formato YYYY-MM-DD", json_response['message']
  end

  test "index should order invoices by created_at desc" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas"
      assert_response :success
      
      json_response = JSON.parse(response.body)
      dates = json_response['data'].map { |inv| inv['created_at'] }
      
      # Verificar que están ordenados descendentemente
      assert_equal dates, dates.sort.reverse
    end
  end

  test "index should update overdue status for pending invoices" do
    # Crear una factura pendiente con fecha vencida
    ClientsService.stub(:client_exists?, true) do
      overdue_invoice = Invoice.create!(
        client_id: 1,
        invoice_number: "INV-TEST-9999",
        issue_date: Date.current,
        due_date: Date.current - 1.day,
        subtotal: 100.00,
        status: 'pending'
      )
      
      ClientsService.stub(:find_client, @client_data) do
        get "/api/v1/facturas"
        assert_response :success
        
        # Recargar la factura y verificar que el estado cambió
        overdue_invoice.reload
        assert_equal 'overdue', overdue_invoice.status
      end
    end
  end

  # ==================== PRUEBAS DE SHOW ====================

  test "should show invoice" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas/#{@invoice.id}"
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert json_response['success']
      assert_equal @invoice.id, json_response['data']['id']
      assert_equal @invoice.invoice_number, json_response['data']['invoice_number']
    end
  end

  test "show should include detailed client data" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas/#{@invoice.id}"
      assert_response :success
      
      json_response = JSON.parse(response.body)
      client = json_response['data']['client']
      
      assert_not_nil client
      assert_equal @client_data['id'], client['id']
      assert_equal @client_data['name'], client['name']
      assert_equal @client_data['email'], client['email']
      assert_equal @client_data['identification'], client['identification']
      assert_equal @client_data['address'], client['address']
    end
  end

  test "should return not_found for non-existent invoice" do
    get "/api/v1/facturas/99999"
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal "Factura no encontrada", json_response['message']
  end

  test "show should not include updated_at in response" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas/#{@invoice.id}"
      assert_response :success
      
      json_response = JSON.parse(response.body)
      assert_nil json_response['data']['updated_at']
    end
  end

  test "show should update overdue status if needed" do
    ClientsService.stub(:client_exists?, true) do
      overdue_invoice = Invoice.create!(
        client_id: 1,
        invoice_number: "INV-TEST-8888",
        issue_date: Date.current,
        due_date: Date.current - 1.day,
        subtotal: 100.00,
        status: 'pending'
      )
      
      ClientsService.stub(:find_client, @client_data) do
        get "/api/v1/facturas/#{overdue_invoice.id}"
        assert_response :success
        
        overdue_invoice.reload
        assert_equal 'overdue', overdue_invoice.status
      end
    end
  end

  # ==================== PRUEBAS DE CREATE ====================

  test "should create invoice with valid data" do
    ClientsService.stub(:client_exists?, true) do
      ClientsService.stub(:find_client, @client_data) do
        assert_difference('Invoice.count', 1) do
          post "/api/v1/facturas", params: {
            invoice: {
              client_id: 1,
              issue_date: Date.current,
              due_date: Date.current + 30.days,
              subtotal: 1500.00,
              tax: 285.00,
              status: 'pending',
              notes: 'Factura de prueba'
            }
          }
        end
        
        assert_response :created
        json_response = JSON.parse(response.body)
        
        assert json_response['success']
        assert_equal "Factura creada exitosamente", json_response['message']
        assert_not_nil json_response['data']
        assert_equal 1, json_response['data']['client_id']
        assert_equal "1500.0", json_response['data']['subtotal']
        assert_equal "285.0", json_response['data']['tax']
        assert_equal "1785.0", json_response['data']['total']
      end
    end
  end

  test "create should generate invoice_number automatically" do
    ClientsService.stub(:client_exists?, true) do
      ClientsService.stub(:find_client, @client_data) do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            issue_date: Date.current,
            subtotal: 1000.00,
            status: 'pending'
          }
        }
        
        assert_response :created
        json_response = JSON.parse(response.body)
        
        assert_not_nil json_response['data']['invoice_number']
        assert_match(/INV-\d{8}-\d{4}/, json_response['data']['invoice_number'])
      end
    end
  end

  test "create should include client data in response" do
    ClientsService.stub(:client_exists?, true) do
      ClientsService.stub(:find_client, @client_data) do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            issue_date: Date.current,
            subtotal: 1000.00,
            status: 'pending'
          }
        }
        
        assert_response :created
        json_response = JSON.parse(response.body)
        
        assert_not_nil json_response['data']['client']
        assert_equal @client_data['id'], json_response['data']['client']['id']
        assert_equal @client_data['name'], json_response['data']['client']['name']
      end
    end
  end

  test "should not create invoice without required fields" do
    ClientsService.stub(:client_exists?, true) do
      assert_no_difference('Invoice.count') do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            status: 'pending'
          }
        }
      end
      
      assert_response :unprocessable_entity
      json_response = JSON.parse(response.body)
      
      assert_not json_response['success']
      assert_equal "No se pudo crear la factura", json_response['message']
      assert_not_nil json_response['errors']
    end
  end

  test "should not create invoice with negative subtotal" do
    ClientsService.stub(:client_exists?, true) do
      assert_no_difference('Invoice.count') do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            issue_date: Date.current,
            subtotal: -100.00,
            status: 'pending'
          }
        }
      end
      
      assert_response :unprocessable_entity
      json_response = JSON.parse(response.body)
      assert_not json_response['success']
    end
  end

  test "should not create invoice with invalid status" do
    ClientsService.stub(:client_exists?, true) do
      assert_no_difference('Invoice.count') do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            issue_date: Date.current,
            subtotal: 1000.00,
            status: 'invalid_status'
          }
        }
      end
      
      assert_response :unprocessable_entity
      json_response = JSON.parse(response.body)
      assert_not json_response['success']
    end
  end

  test "should not create invoice with non-existent client" do
    ClientsService.stub(:client_exists?, false) do
      assert_no_difference('Invoice.count') do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 999,
            issue_date: Date.current,
            subtotal: 1000.00,
            status: 'pending'
          }
        }
      end
      
      assert_response :unprocessable_entity
      json_response = JSON.parse(response.body)
      assert_not json_response['success']
    end
  end

  test "should not create invoice with issue_date in the past" do
    ClientsService.stub(:client_exists?, true) do
      assert_no_difference('Invoice.count') do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            issue_date: Date.current - 1.day,
            subtotal: 1000.00,
            status: 'pending'
          }
        }
      end
      
      assert_response :unprocessable_entity
      json_response = JSON.parse(response.body)
      assert_not json_response['success']
    end
  end

  test "create should calculate total automatically" do
    ClientsService.stub(:client_exists?, true) do
      ClientsService.stub(:find_client, @client_data) do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            issue_date: Date.current,
            subtotal: 1000.00,
            tax: 190.00,
            status: 'pending'
          }
        }
        
        assert_response :created
        json_response = JSON.parse(response.body)
        
        assert_equal "1190.0", json_response['data']['total']
      end
    end
  end

  test "create should handle nil tax" do
    ClientsService.stub(:client_exists?, true) do
      ClientsService.stub(:find_client, @client_data) do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            issue_date: Date.current,
            subtotal: 1000.00,
            status: 'pending'
          }
        }
        
        assert_response :created
        json_response = JSON.parse(response.body)
        
        assert_equal "1000.0", json_response['data']['total']
      end
    end
  end

  # ==================== PRUEBAS DE CASOS EDGE ====================

  test "index should handle multiple filters at once" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas", params: {
        client_id: 1,
        status: 'pending',
        fechaInicio: Date.current.to_s
      }
      
      assert_response :success
      json_response = JSON.parse(response.body)
      assert json_response['success']
    end
  end

  test "index should return empty array when no invoices match filters" do
    ClientsService.stub(:find_client, @client_data) do
      get "/api/v1/facturas", params: {
        invoice_number: "NON-EXISTENT-NUMBER"
      }
      
      assert_response :success
      json_response = JSON.parse(response.body)
      
      assert json_response['success']
      assert_equal 0, json_response['total_invoices']
      assert_equal [], json_response['data']
    end
  end

  test "should handle invoices without client data gracefully" do
    ClientsService.stub(:find_client, nil) do
      get "/api/v1/facturas"
      assert_response :success
      
      json_response = JSON.parse(response.body)
      # La respuesta debería ser exitosa aunque no tenga datos del cliente
      assert json_response['success']
    end
  end

  test "create with duplicate invoice_number should fail" do
    ClientsService.stub(:client_exists?, true) do
      existing_number = invoices(:one).invoice_number
      
      assert_no_difference('Invoice.count') do
        post "/api/v1/facturas", params: {
          invoice: {
            client_id: 1,
            invoice_number: existing_number,
            issue_date: Date.current,
            subtotal: 1000.00,
            status: 'pending'
          }
        }
      end
      
      assert_response :unprocessable_entity
    end
  end
end

