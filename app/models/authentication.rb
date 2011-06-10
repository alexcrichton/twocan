class Authentication
  include Mongoid::Document

  field :provider
  field :uid
  field :token

  validates_presence_of :provider, :uid, :token
  validates_uniqueness_of :uid, :scope => :provider

end
