class Section
  include Mongoid::Document

  field :title
  field :data, :type => BSON::Binary

  validates_presence_of :title, :data

  embedded_in :crossword

  def data= data
    super BSON::Binary.new(data)
  end

end
