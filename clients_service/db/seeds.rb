clients_data = [
  {
    name: "Juan Pérez",
    identification: "12345678",
    email: "juanperez@gmail.com",
    address: "Carrera 7 #23-45, Bogotá"
  },
  {
    name: "María López",
    identification: "87654321",
    email: "marialopez@gmail.com",
    address: "Calle 10 #45-67, Medellín"
  },
  {
    name: "Carlos García",
    identification: "20123456789",
    email: "carlosgarcia@gmail.com",
    address: "Avenida 6N #28-50, Cali"
  },
  {
    name: "Ana Martínez",
    identification: "11223344",
    email: "anamartinez@gmail.com",
    address: "Carrera 15 #85-23, Cartagena"
  },
  {
    name: "Pedro Sánchez",
    identification: "001234567",
    email: "pedrosanchez@gmail.com",
    address: "Calle 93 #14-35, Barranquilla"
  }
]

clients_data.each do |client_data|
  Client.create!(client_data)
end
