class ApplicationController < ActionController::Base
  before_filter :ensure_session_token
  before_filter :ensure_authenticity_token

  protect_from_forgery

  def ensure_session_token
    session[:token] ||= current_user.try(:token) || SecureRandom.hex(15)
  end

  def ensure_authenticity_token
    form_authenticity_token()
  end

  def current_ability
    @current_ability ||= Ability.new current_user, session
  end

end
