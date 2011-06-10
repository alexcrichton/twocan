class Ability
  include CanCan::Ability

  def initialize user, session
    can [:create, :read], Crossword
    can :destroy, Crossword, :session_token => session[:token]
  end
end
