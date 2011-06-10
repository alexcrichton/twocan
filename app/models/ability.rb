class Ability
  include CanCan::Ability

  def initialize user, session
    tokens = [session[:token]]
    tokens << user.token if user

    can [:create, :read], Crossword
    can :destroy, Crossword, :session_token.in => tokens.uniq
  end
end
