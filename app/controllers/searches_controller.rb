class SearchesController < ApplicationController

  def flush
    Rifle.flush
    render json: {status: 'success'}, status: :ok
  end

  def store
    urn = params[:urn]
    payload = JSON.parse(request.body.read)
    Rifle.store(urn, payload)
    render json: {status: 'success'}, status: :ok
  end

  def search
    words = params[:q]
    results = Rifle.search(words)
    render json: results, status: :ok
  end

end
