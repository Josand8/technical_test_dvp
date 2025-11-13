require 'rails_helper'

RSpec.describe Invoice, type: :model do
  before do
    allow(ClientsService).to receive(:client_exists?).and_return(true)
  end

  describe 'validations' do
    it 'should be valid with valid attributes' do
      invoice = build(:invoice)
      expect(invoice).to be_valid
    end

    it 'should require invoice_number to be unique' do
      existing_invoice = create(:invoice, invoice_number: 'INV-20251112-0001')
      new_invoice = build(:invoice, invoice_number: existing_invoice.invoice_number)
      expect(new_invoice).not_to be_valid
      expect(new_invoice.errors[:invoice_number]).to include("ya está registrado")
    end

    it 'should not allow issue_date in the past' do
      invoice = build(:invoice, issue_date: Date.current - 1.day)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:issue_date]).to include("no puede ser anterior a la fecha actual")
    end

    it 'should require subtotal' do
      invoice = build(:invoice, subtotal: nil)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:subtotal]).to include("no puede estar vacío")
    end

    it 'should not allow negative subtotal' do
      invoice = build(:invoice, subtotal: -100.00)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:subtotal]).to include("debe ser mayor o igual a 0")
    end

    it 'should not allow negative tax' do
      invoice = build(:invoice, tax: -50.00)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:tax]).to include("debe ser mayor o igual a 0")
    end

    it 'should validate status inclusion' do
      invoice = build(:invoice, status: 'invalid_status')
      expect(invoice).not_to be_valid
      expect(invoice.errors[:status]).to include("debe ser pending, paid, overdue o cancelled")
    end

    it 'should require client_id' do
      invoice = build(:invoice, client_id: nil)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:client_id]).to include("no puede estar vacío")
    end

    it 'should validate client exists' do
      allow(ClientsService).to receive(:client_exists?).and_return(false)
      invoice = build(:invoice, client_id: 999)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:client_id]).to include("el cliente no existe en el servicio de clientes")
    end
  end

  describe 'callbacks' do
    it 'should generate invoice_number automatically on create' do
      invoice = create(:invoice, invoice_number: nil)
      expect(invoice.invoice_number).not_to be_nil
      expect(invoice.invoice_number).to match(/INV-\d{8}-\d{4}/)
    end

    it 'should calculate total from subtotal and tax' do
      invoice = build(:invoice, subtotal: 1000.00, tax: 190.00)
      invoice.valid?
      expect(invoice.total).to eq(1190.00)
    end

    it 'should set default issue_date on create' do
      invoice = create(:invoice, issue_date: nil)
      expect(invoice.issue_date).to eq(Date.current)
    end

    it 'should change status to overdue if due_date has passed' do
      invoice = build(:invoice, due_date: Date.current - 1.day, status: 'pending')
      invoice.valid?
      expect(invoice.status).to eq('overdue')
    end
  end

  describe 'scopes' do
    before do
      create(:invoice, status: 'pending', client_id: 1)
      create(:invoice, status: 'paid', client_id: 1)
      create(:invoice, status: 'overdue', client_id: 2)
    end

    it 'pending scope should return only pending invoices' do
      pending_invoices = Invoice.pending
      expect(pending_invoices.count).to eq(1)
      expect(pending_invoices.all? { |inv| inv.status == 'pending' }).to be true
    end

    it 'by_client scope should filter by client_id' do
      client_invoices = Invoice.by_client(1)
      expect(client_invoices.count).to eq(2)
      expect(client_invoices.all? { |inv| inv.client_id == 1 }).to be true
    end
  end
end
