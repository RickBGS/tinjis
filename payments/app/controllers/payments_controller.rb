class PaymentsController < ApplicationController
  include Response

  def create
    json_response({id: 0, result: true}, :created)
  end
end