class Ability
  include CanCan::Ability

  def initialize user, session
    token = user.try(:token) || session[:token]

    can [:create, :read], Crossword
    can :destroy, Crossword, :session_token => token
  end
end
