class User
  include Mongoid::Document

  devise :rememberable

  field :provider
  field :uid
  field :token
  field :email

  validates_presence_of :provider, :uid, :token, :email
  validates_uniqueness_of :uid, :scope => :provider

end
