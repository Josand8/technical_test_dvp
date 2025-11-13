require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'validations' do
    subject { build(:client) }

    # Usar expect en lugar de should para mejor compatibilidad con mensajes personalizados
    it 'validates presence of name' do
      client = build(:client, name: nil)
      expect(client).not_to be_valid
      expect(client.errors[:name]).to include("no puede estar vacío")
    end

    it 'validates length of name' do
      client = build(:client, name: 'A')
      expect(client).not_to be_valid
      expect(client.errors[:name]).to include("debe tener entre 2 y 100 caracteres")
    end

    it 'validates uniqueness of email' do
      create(:client, email: 'test@example.com')
      duplicate = build(:client, email: 'test@example.com')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("ya está registrado")
    end

    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }

    context 'when name is too short' do
      it 'is not valid' do
        client = build(:client, name: 'A')
        expect(client).not_to be_valid
        expect(client.errors[:name]).to include("debe tener entre 2 y 100 caracteres")
      end
    end

    context 'when name is too long' do
      it 'is not valid' do
        client = build(:client, name: 'A' * 101)
        expect(client).not_to be_valid
        expect(client.errors[:name]).to include("debe tener entre 2 y 100 caracteres")
      end
    end

    context 'when identification is too long' do
      it 'is not valid' do
        client = build(:client, identification: 'A' * 21)
        expect(client).not_to be_valid
        expect(client.errors[:identification]).to include("no puede tener más de 20 caracteres")
      end
    end

    context 'when address is too long' do
      it 'is not valid' do
        client = build(:client, address: 'A' * 501)
        expect(client).not_to be_valid
        expect(client.errors[:address]).to include("no puede tener más de 500 caracteres")
      end
    end

    context 'when identification is blank' do
      it 'is valid' do
        client = build(:client, :without_identification)
        expect(client).to be_valid
      end
    end

    context 'when address is blank' do
      it 'is valid' do
        client = build(:client, :without_address)
        expect(client).to be_valid
      end
    end

    context 'when email is duplicate' do
      it 'is not valid' do
        create(:client, email: 'test@example.com')
        duplicate = build(:client, email: 'test@example.com')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:email]).to include("ya está registrado")
      end
    end

    context 'when identification is duplicate' do
      it 'is not valid' do
        create(:client, identification: '12345678')
        duplicate = build(:client, identification: '12345678')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:identification]).to include("ya está registrado")
      end
    end
  end

  describe 'normalizations' do
    context 'email normalization' do
      it 'normalizes email to lowercase' do
        client = create(:client, email: 'UPPERCASE@EXAMPLE.COM')
        expect(client.email).to eq('uppercase@example.com')
      end

      it 'normalizes email with mixed case' do
        client = create(:client, email: 'TeSt@ExAmPlE.cOm')
        expect(client.email).to eq('test@example.com')
      end
    end

    context 'identification normalization' do
      it 'removes spaces from identification' do
        client = create(:client, identification: '  12345678  ')
        expect(client.identification).to eq('12345678')
      end
    end
  end

  describe 'scopes' do
    let!(:client1) { create(:client, name: 'Juan Test', email: 'juan_scope@example.com', identification: 'SCOPE001') }
    let!(:client2) { create(:client, name: 'María Test', email: 'maria_scope@example.com', identification: 'SCOPE002') }

    describe '.by_name' do
      it 'finds clients by name (case insensitive)' do
        results = Client.by_name('juan')
        expect(results).to include(client1)
        expect(results).not_to include(client2)
      end
    end

    describe '.by_email' do
      it 'finds clients by email (case insensitive)' do
        results = Client.by_email('juan_scope')
        expect(results).to include(client1)
        expect(results).not_to include(client2)
      end
    end
  end
end

