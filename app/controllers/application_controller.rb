class ApplicationController < ActionController::Base
  respond_to :json
  session :off
end