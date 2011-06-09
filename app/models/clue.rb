class Clue
  include Mongoid::Document

  field :text
  field :row
  field :column
  field :direction
  field :number

  embedded_in :crossword

  scope :down, where(:direction => 'down')
  scope :across, where(:direction => 'across')

  validates_presence_of :text, :row, :column, :direction, :number
end
