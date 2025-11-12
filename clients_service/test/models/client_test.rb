require "test_helper"

class ClientTest < ActiveSupport::TestCase
  def setup
    @client = Client.new(
      name: "Juan Pérez",
      identification: "12345678",
      email: "juanperez@gmail.com",
      address: "Carrera 7 #23-45, Bogotá"
    )
  end

  test "should be valid with valid attributes" do
    assert @client.valid?
  end

  test "should not be valid without name" do
    @client.name = nil
    assert_not @client.valid?
    assert_includes @client.errors[:name], "no puede estar vacío"
  end

  test "should not be valid without email" do
    @client.email = nil
    assert_not @client.valid?
    assert_includes @client.errors[:email], "no puede estar vacío"
  end

  test "should not be valid with invalid email format" do
    @client.email = "invalid_email"
    assert_not @client.valid?
    assert_includes @client.errors[:email], "no tiene un formato válido"
  end

  test "should not be valid with duplicate email" do
    @client.save
    duplicate_client = @client.dup
    assert_not duplicate_client.valid?
    assert_includes duplicate_client.errors[:email], "ya está registrado"
  end

  test "should normalize email to lowercase" do
    client = Client.new(
      name: "Test User",
      email: "UPPERCASE@EXAMPLE.COM"
    )
    client.save
    assert_equal "uppercase@example.com", client.email
  end

  test "should normalize email with mixed case and spaces" do
    client = Client.new(
      name: "Test User",
      email: "TeSt@ExAmPlE.cOm"
    )
    client.save
    assert_equal "test@example.com", client.email
  end

  test "should not be valid with name shorter than 2 characters" do
    @client.name = "A"
    assert_not @client.valid?
    assert_includes @client.errors[:name], "debe tener entre 2 y 100 caracteres"
  end

  test "should not be valid with name longer than 100 characters" do
    @client.name = "A" * 101
    assert_not @client.valid?
    assert_includes @client.errors[:name], "debe tener entre 2 y 100 caracteres"
  end

  test "should be valid with identification blank" do
    @client.identification = nil
    assert @client.valid?
  end

  test "should not be valid with identification longer than 20 characters" do
    @client.identification = "A" * 21
    assert_not @client.valid?
    assert_includes @client.errors[:identification], "no puede tener más de 20 caracteres"
  end

  test "should be valid with address blank" do
    @client.address = nil
    assert @client.valid?
  end

  test "should not be valid with address longer than 500 characters" do
    @client.address = "A" * 501
    assert_not @client.valid?
    assert_includes @client.errors[:address], "no puede tener más de 500 caracteres"
  end

  test "should not be valid with duplicate identification" do
    @client.save
    duplicate_client = Client.new(
      name: "María López",
      email: "maria.lopez@example.com",
      identification: @client.identification
    )
    assert_not duplicate_client.valid?
    assert_includes duplicate_client.errors[:identification], "ya está registrado"
  end

  test "should normalize identification before save" do
    client = Client.new(
      name: "Test User",
      email: "test_ident@example.com",
      identification: "  12345678  "
    )
    client.save
    assert_equal "12345678", client.identification
  end

  test "by_name scope should find clients by name" do
    client = Client.create!(name: "Juan Test", email: "juan_scope@example.com")
    results = Client.by_name("juan")
    assert results.exists?(id: client.id)
  end

  test "by_email scope should find clients by email" do
    client = Client.create!(name: "Email Test", email: "email.scope@example.com")
    results = Client.by_email("email.scope")
    assert results.exists?(id: client.id)
  end
end

