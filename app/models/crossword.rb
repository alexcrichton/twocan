class Crossword
  include Mongoid::Document

  field :binary_data, :type => BSON::Binary 
  field :width, :type => Integer
  field :height, :type => Integer
  field :solution
  field :clues, :type => Array

  validate :binary_file_is_valid
  # validates_presence_of :binary_data, :width, :height, :solution

  attr_accessor :binary_file

  def binary_file_is_valid
    return unless @binary_file.present?
    self[:binary_data] = nil

    data = @binary_file.open.binmode.read
    p data
    parser = Parser.new.tap{ |p| p.parse! data }

    self[:width]    = parser.width
    self[:height]   = parser.height
    self[:clues]    = parser.clues.map{ |c| c.encode('utf-8') }
    self[:solution] = parser.solution

    @binary_file.rewind
    self[:binary_data] = @binary_file.read
  rescue ParseError, ChecksumError, CompatibilityError => e
    puts e.message
    puts e.backtrace
    errors[:binary_file] << 'is an invalid crossword file.'
    p errors
  end

  def to_puz
    raise 'Not implemented yet!'
  end

end
