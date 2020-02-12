class PaymentsController < ApplicationController
  include Response

  def create
    return json_response({result: false, message: 'missing parameter'}, :bad_request) if missing_param?
    return json_response({result: false, message: 'invalid value'}, :bad_request) if !valid_value?

    return json_response({id: SecureRandom.hex(10), result: true}, :created) if paid?

    json_response({result: false, message: 'cannot process payment'}, :unprocessable_entity)
  end

  private

  def missing_param?
    !params.key?(:currency) || !params.key?(:value) || !params.key?(:customer_id)
  end

  def valid_value?
    value = params[:value]
    params[:value].to_f >= 0.00
  end

  def paid?
    SecureRandom.random_number(2) == 1
  end
end