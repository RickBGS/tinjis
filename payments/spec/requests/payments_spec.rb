require 'rails_helper'

RSpec.describe 'Payments API', type: :request do
  describe 'POST /payments' do
  	let(:currency) { Faker::Currency.code }
  	let(:value) { Faker::Number.decimal(l_digits: 2) }
  	let(:customer_id) { Faker::Number.number(digits: 10) }

    let(:valid_attributes) { { currency: currency, value: value, customer_id: customer_id } }

    context 'when the request is valid' do
      before { post '/payments', params: valid_attributes }

      it { expect(response).to have_http_status(:created) }

      it 'creates a payment' do
        expect(json['id']).not_to be_nil
      end

      it 'returns result true' do
        expect(json['result']).to be_truthy
      end
    end

    context 'when the request is missing the currency' do
      let(:attributes) { valid_attributes.except(:currency) }

      before { post '/payments', params: attributes }

      it { expect(response).to have_http_status(:bad_request) }

      it 'does not create a payment' do
        expect(json['id']).to be_nil
      end

      it 'returns result false' do
        expect(json['result']).to be_falsey
      end
    end

    context 'when the request is missing the value' do
      let(:attributes) { valid_attributes.except(:value) }

      before { post '/payments', params: attributes }

      it { expect(response).to have_http_status(:bad_request) }

      it 'does not create a payment' do
        expect(json['id']).to be_nil
      end

      it 'returns result false' do
        expect(json['result']).to be_falsey
      end
    end

    context 'when the request is missing the customer_id' do
      let(:attributes) { valid_attributes.except(:customer_id) }

      before { post '/payments', params: attributes }

      it { expect(response).to have_http_status(:bad_request) }

      it 'does not create a payment' do
        expect(json['id']).to be_nil
      end

      it 'returns result false' do
        expect(json['result']).to be_falsey
      end
    end

    context 'when the request has negative value' do
      let(:attributes) { valid_attributes.merge(value: -11.11) }

      before { post '/payments', params: attributes }

      it { expect(response).to have_http_status(:bad_request) }

      it 'does not create a payment' do
        expect(json['id']).to be_nil
      end

      it 'returns result false' do
        expect(json['result']).to be_falsey
      end
    end
  end
end
