require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  def setup
    # Mock del ClientsService para las pruebas
    @valid_client_data = {
      'id' => 1,
      'name' => 'Cliente Test',
      'email' => 'test@example.com'
    }
  end

  # ==================== PRUEBAS DE VALIDACIONES ====================

  test "should be valid with valid attributes" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        due_date: Date.current + 30.days,
        subtotal: 1000.00,
        tax: 190.00,
        status: 'pending'
      )
      assert invoice.valid?, "La factura debería ser válida pero tiene errores: #{invoice.errors.full_messages}"
    end
  end

  test "should require invoice_number to be unique" do
    ClientsService.stub(:client_exists?, true) do
      invoice1 = invoices(:one)
      invoice2 = Invoice.new(
        client_id: 2,
        invoice_number: invoice1.invoice_number,
        issue_date: Date.current,
        subtotal: 500.00,
        status: 'pending'
      )
      assert_not invoice2.valid?
      assert_includes invoice2.errors[:invoice_number], "ya está registrado"
    end
  end

  test "should require issue_date when explicitly set to nil and saved" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.create(
        client_id: 1,
        subtotal: 1000.00,
        status: 'pending'
      )
      # El callback set_default_issue_date asigna la fecha actual automáticamente
      assert_not_nil invoice.issue_date
      
      # Pero si intentamos actualizarlo a nil después de crearlo, debe fallar la validación
      invoice.issue_date = nil
      assert_not invoice.valid?
      assert_includes invoice.errors[:issue_date], "no puede estar vacío"
    end
  end

  test "should not allow issue_date in the past" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current - 1.day,
        subtotal: 1000.00,
        status: 'pending'
      )
      assert_not invoice.valid?
      assert_includes invoice.errors[:issue_date], "no puede ser anterior a la fecha actual"
    end
  end

  test "should require subtotal" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: nil,
        status: 'pending'
      )
      assert_not invoice.valid?
      assert_includes invoice.errors[:subtotal], "no puede estar vacío"
    end
  end

  test "should not allow negative subtotal" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: -100.00,
        status: 'pending'
      )
      assert_not invoice.valid?
      assert_includes invoice.errors[:subtotal], "debe ser mayor o igual a 0"
    end
  end

  test "should allow tax to be nil" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 1000.00,
        tax: nil,
        status: 'pending'
      )
      assert invoice.valid?
    end
  end

  test "should not allow negative tax" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 1000.00,
        tax: -50.00,
        status: 'pending'
      )
      assert_not invoice.valid?
      assert_includes invoice.errors[:tax], "debe ser mayor o igual a 0"
    end
  end

  test "should validate status inclusion" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 1000.00,
        status: 'invalid_status'
      )
      assert_not invoice.valid?
      assert_includes invoice.errors[:status], "debe ser pending, paid, overdue o cancelled"
    end
  end

  test "should allow valid status values" do
    ClientsService.stub(:client_exists?, true) do
      %w[pending paid overdue cancelled].each do |valid_status|
        invoice = Invoice.new(
          client_id: 1,
          issue_date: Date.current,
          subtotal: 1000.00,
          status: valid_status
        )
        assert invoice.valid?, "El status '#{valid_status}' debería ser válido"
      end
    end
  end

  test "should require client_id" do
    invoice = Invoice.new(
      client_id: nil,
      issue_date: Date.current,
      subtotal: 1000.00,
      status: 'pending'
    )
    assert_not invoice.valid?
    assert_includes invoice.errors[:client_id], "no puede estar vacío"
  end

  test "should validate client exists" do
    ClientsService.stub(:client_exists?, false) do
      invoice = Invoice.new(
        client_id: 999,
        issue_date: Date.current,
        subtotal: 1000.00,
        status: 'pending'
      )
      assert_not invoice.valid?
      assert_includes invoice.errors[:client_id], "el cliente no existe en el servicio de clientes"
    end
  end

  # ==================== PRUEBAS DE CALLBACKS ====================

  test "should generate invoice_number automatically on create" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 1000.00,
        status: 'pending'
      )
      invoice.save
      assert_not_nil invoice.invoice_number
      assert_match(/INV-\d{8}-\d{4}/, invoice.invoice_number)
    end
  end

  test "should not override existing invoice_number" do
    ClientsService.stub(:client_exists?, true) do
      custom_number = "CUSTOM-001"
      invoice = Invoice.new(
        client_id: 1,
        invoice_number: custom_number,
        issue_date: Date.current,
        subtotal: 1000.00,
        status: 'pending'
      )
      invoice.save
      assert_equal custom_number, invoice.invoice_number
    end
  end

  test "should calculate total from subtotal and tax" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 1000.00,
        tax: 190.00,
        status: 'pending'
      )
      invoice.valid?
      assert_equal 1190.00, invoice.total
    end
  end

  test "should calculate total with zero tax when tax is nil" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 1000.00,
        tax: nil,
        status: 'pending'
      )
      invoice.valid?
      assert_equal 1000.00, invoice.total
    end
  end

  test "should set default issue_date on create" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        subtotal: 1000.00,
        status: 'pending'
      )
      invoice.save
      assert_equal Date.current, invoice.issue_date
    end
  end

  test "should not override provided issue_date" do
    ClientsService.stub(:client_exists?, true) do
      custom_date = Date.current + 1.day
      invoice = Invoice.new(
        client_id: 1,
        issue_date: custom_date,
        subtotal: 1000.00,
        status: 'pending'
      )
      invoice.save
      assert_equal custom_date, invoice.issue_date
    end
  end

  test "should change status to overdue if due_date has passed" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        due_date: Date.current - 1.day,
        subtotal: 1000.00,
        status: 'pending'
      )
      invoice.valid?
      assert_equal 'overdue', invoice.status
    end
  end

  test "should not change status to overdue if status is not pending" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        due_date: Date.current - 1.day,
        subtotal: 1000.00,
        status: 'paid'
      )
      invoice.valid?
      assert_equal 'paid', invoice.status
    end
  end

  test "should not change status if due_date is blank" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        due_date: nil,
        subtotal: 1000.00,
        status: 'pending'
      )
      invoice.valid?
      assert_equal 'pending', invoice.status
    end
  end

  # ==================== PRUEBAS DE SCOPES ====================

  test "pending scope should return only pending invoices" do
    pending_invoices = Invoice.pending
    assert_equal 1, pending_invoices.count
    assert pending_invoices.all? { |inv| inv.status == 'pending' }
  end

  test "paid scope should return only paid invoices" do
    paid_invoices = Invoice.paid
    assert_equal 1, paid_invoices.count
    assert paid_invoices.all? { |inv| inv.status == 'paid' }
  end

  test "overdue scope should return only overdue invoices" do
    overdue_invoices = Invoice.overdue
    assert_equal 1, overdue_invoices.count
    assert overdue_invoices.all? { |inv| inv.status == 'overdue' }
  end

  test "by_client scope should filter by client_id" do
    client_invoices = Invoice.by_client(1)
    assert_equal 2, client_invoices.count
    assert client_invoices.all? { |inv| inv.client_id == 1 }
  end

  # ==================== PRUEBAS DE CASOS EDGE ====================

  test "should handle zero subtotal" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 0.00,
        tax: 0.00,
        status: 'pending'
      )
      assert invoice.valid?
      assert_equal 0.00, invoice.total
    end
  end

  test "should handle large amounts" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 999999.99,
        tax: 189999.99,
        status: 'pending'
      )
      assert invoice.valid?
      assert_equal 1189999.98, invoice.total
    end
  end

  test "should handle due_date on current date" do
    ClientsService.stub(:client_exists?, true) do
      invoice = Invoice.new(
        client_id: 1,
        issue_date: Date.current,
        due_date: Date.current,
        subtotal: 1000.00,
        status: 'pending'
      )
      invoice.valid?
      assert_equal 'pending', invoice.status
    end
  end

  test "should generate sequential invoice numbers" do
    ClientsService.stub(:client_exists?, true) do
      invoice1 = Invoice.create!(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 100.00,
        status: 'pending'
      )
      
      invoice2 = Invoice.create!(
        client_id: 1,
        issue_date: Date.current,
        subtotal: 200.00,
        status: 'pending'
      )
      
      # Extraer los números secuenciales
      number1 = invoice1.invoice_number.split('-').last.to_i
      number2 = invoice2.invoice_number.split('-').last.to_i
      
      assert number2 > number1, "El número de factura debería ser secuencial"
    end
  end
end

