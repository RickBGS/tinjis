require 'rails_helper'

RSpec.describe 'Probes API', type: :request do
  describe 'GET /health' do
    before { get '/health' }

    it { expect(response).to have_http_status(:ok) }
  end
end
