class HomeController < ApplicationController

  include Devise::Controllers::Rememberable
  skip_filter :verify_authenticity_token, :only => :pusher_auth

  def pusher_auth
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    render :json => response
  end

  def omniauth
    auth = env['omniauth.auth']
    user = User.find_or_initialize_by(
      :provider => auth['provider'],
      :uid      => auth['uid']
    )

    user.token ||= session[:token]
    user.email ||= auth['email'] || auth['user_info']['email']
    user.save!

    # If we created some crosswords, and then logged in to a previously created
    # account, then we should take ownership of all the crosswords
    Crossword.where(:session_token => session[:token]).
      update_all(:session_token => user.token)

    flash[:notice]  = 'Logged in!'
    session[:token] = user.token
    remember_me user
    sign_in_and_redirect user
  end

end
