if Rails.env.development?
  Invoice.destroy_all
end

# IDs de clientes existentes en el servicio de clientes
client_ids = [1, 2, 3, 4, 5]

invoices_data = [
  {
    client_id: client_ids[0],
    subtotal: 1000.00,
    tax: 190.00,
    due_date: Date.current + 30.days,
    status: 'pending',
    notes: 'Factura por servicios de consultoría'
  },
  {
    client_id: client_ids[1],
    subtotal: 2500.00,
    tax: 475.00,
    due_date: Date.current + 15.days,
    status: 'pending',
    notes: 'Desarrollo de aplicación web'
  },
  {
    client_id: client_ids[2],
    subtotal: 500.00,
    tax: 95.00,
    issue_date: Date.current,
    due_date: Date.current + 30.days,
    status: 'paid',
    notes: 'Mantenimiento mensual'
  },
  {
    client_id: client_ids[0],
    subtotal: 1500.00,
    tax: 285.00,
    issue_date: Date.current,
    due_date: Date.current + 15.days,
    status: 'overdue',
    notes: 'Soporte técnico especializado'
  },
  {
    client_id: client_ids[3],
    subtotal: 3000.00,
    tax: 570.00,
    due_date: Date.current + 45.days,
    status: 'pending',
    notes: 'Proyecto de integración de sistemas'
  }
]

invoices_data.each do |invoice_data|
  invoice = Invoice.create!(invoice_data)
  client_info = ClientsService.find_client(invoice.client_id)
  client_name = client_info ? client_info['name'] : "Cliente ID #{invoice.client_id}"
  puts "✅ Factura creada: #{invoice.invoice_number} - Cliente: #{client_name} - Total: $#{invoice.total}"
end
