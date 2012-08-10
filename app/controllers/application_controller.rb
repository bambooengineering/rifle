require 'session_off'

class ApplicationController < ActionController::Base
  respond_to :json
  session :off
end