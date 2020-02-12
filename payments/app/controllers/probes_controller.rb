class ProbesController < ApplicationController
  include Response

  def health
    json_response({}, :ok)
  end
end