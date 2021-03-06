module Crosswords
  class ParseError < StandardError; end
  class ChecksumError < StandardError; end

  class Section
    attr_accessor :title, :length, :cksum, :data

    def self.parse! io
      self.new.tap do |s|
        s.title  = io.sysread(0x4)
        s.length = io.sysread(0x2).unpack('v').first
        s.cksum  = io.sysread(0x2).unpack('v').first
        s.data   = io.sysread(s.length)

        raise ParseError unless io.sysread(0x1) == "\x00"
      end
    end
  end

  class Grid
    def initialize crossword
      @crossword = crossword
    end

    def parse! io
      @board = io.sysread(@crossword.width * @crossword.height).chars.to_a
    end

    def to_s
      @board.join
    end

    def [] row, column
      if row < 0 || column < 0 || row >= @crossword.height ||
          column >= @crossword.width
        '.'
      else
        @board[row * @crossword.width + column]
      end
    end
  end

  class SysStringIO < StringIO
    alias :sysseek :seek

    def binmode?
      true
    end
  end

  class Parser
    attr_accessor :width, :height, :solution, :progress, :title, :author,
      :copyright, :clues, :sections, :notes

    # Parse the given IO stream. For the specifics on the format of a crossword,
    # see http://code.google.com/p/puz/wiki/FileFormat
    #
    # @param [IO, String] io the IO stream that is readable or a string that is
    #    a crossword file
    #
    # @raise [ParseError] if the stream given is not a valid crossword file
    # @raise [ChecksumError] if the checksums given in the stream do not match
    def parse! io
      io = SysStringIO.new(io) if io.is_a?(String)
      io = io.binmode unless io.binmode?

      @cksum    = io.sysread(0x2).unpack('v').first
      magic     = io.sysread(0xc).unpack('Z11').first
      raise ParseError if magic != 'ACROSS&DOWN'

      @cib_cksum = io.sysread(0x2).unpack('v').first
      @masked_low_cksum  = io.sysread(0x4).unpack('C4')
      @masked_high_cksum = io.sysread(0x4).unpack('C4')

      @version = io.sysread(0x4).unpack('Z3').first

      _garbage   = io.sysread(0x2)
      @sol_cksum = io.sysread(0x2).unpack('v').first
      _garbage   = io.sysread(0xc)
      @width     = io.sysread(0x1).unpack('C').first
      @height    = io.sysread(0x1).unpack('C').first
      num_clues  = io.sysread(0x2).unpack('v').first
      _garbage   = io.sysread(0x2)
      @scrambled = io.sysread(0x2).unpack('v').first

      @solution = Grid.new(self).tap{ |g| g.parse! io }
      @progress = Grid.new(self).tap{ |g| g.parse! io }

      @title     = readline io
      @author    = readline io
      @copyright = readline io

      @unprocessed_clues = []
      num_clues.times { @unprocessed_clues << readline(io) }
      @notes = readline io

      @sections = []
      loop { @sections << Section.parse!(io) } rescue EOFError

      validate io
      process_clues
      true
    rescue EOFError, SystemCallError, IOError => e
      raise ParseError
    end

    protected

    # You can't mix calls to sysread and readline on an IO object, so we have
    # to have our own custom 'readline' method. It was chosen to use all sysread
    # calls because they will all raise EOFError. Otherwise, there's many places
    # we need to read a specific number of bytes, but the 'read' method doesn't
    # raise EOFError, it just returns nil
    def readline io
      ''.tap do |string|
        while (c = io.sysread(0x1)) != "\x00"
          string << c
        end
        string.force_encoding 'iso-8859-1'
        string.encode! 'utf-8'
      end
    end

    # Process all of the clues to figure out where they go on the grid and what
    # the number of each clue should be
    def process_clues
      @clues = []
      number = 1
      added  = false

      @height.times { |row|
        @width.times { |col|
          next if @solution[row, col] == '.'

          if @solution[row, col - 1] == '.' && @solution[row, col + 1] != '.'
            @clues << processed_clue_for(row, col, 'across', number)
            added = true
          end

          if @solution[row - 1, col] == '.' && @solution[row + 1, col] != '.'
            @clues << processed_clue_for(row, col, 'down', number)
            added = true
          end

          number += 1 if added
          added = false
        }
      }
    end

    def processed_clue_for row, col, dir, number
      raise ParseError if @unprocessed_clues.empty?

      Clue.new{ |c|
        c.text      = @unprocessed_clues.shift.encode('utf-8')
        c.row       = row
        c.column    = col
        c.direction = dir
        c.number    = number
      }
    end

    # Validates checksums of an IO. Assumes #parse! has been previously called.
    # For the details on the checksums, see the same website mentioned in
    # #parse!
    #
    # @param [IO] io the I/O object which is read from
    def validate io
      # Initially validate the CIB checksum
      io.sysseek 0x2c # start of the CIB header
      raise ChecksumError if @cib_cksum != cksum(io, 8)

      # Now validate the entire puzzle checksum
      ck = @cib_cksum
      ck = cksum io, @width * @height, ck # solution
      ck = cksum io, @width * @height, ck # grid
      ck = cksum io, @title.length + 1, ck
      ck = cksum io, @author.length + 1, ck
      ck = cksum io, @copyright.length + 1, ck
      @unprocessed_clues.each_with_index { |c, i|
        ck = cksum io, c.length, ck
        raise ParseError unless io.sysread(0x1) == "\x00"
      }

      # In version 1.2, notes are skipped in checksums. In version 1.3, only
      # 0-length notes are skipped
      if @version == '1.3' && @notes.length > 0
        ck = cksum io, @notes.length + 1, ck
      else
        readline(io) # Skip the notes
      end

      raise ChecksumError if ck != @cksum

      # Now validate each of the checksums of the sections
      @sections.each { |section|
        io.sysseek 0x8, IO::SEEK_CUR # skip title, length, checksum
        raise ChecksumError if cksum(io, section.length) != section.cksum
        raise ParseError unless io.sysread(0x1) == "\x00"
      }

      # Now finally validate the masked checksums
      io.sysseek 0x34 # Start of the solution grids
      c_sol  = cksum io, @width * @height
      c_grid = cksum io, @width * @height

      c_part = cksum io, @title.length + 1
      c_part = cksum io, @author.length + 1, c_part
      c_part = cksum io, @copyright.length + 1, c_part
      @unprocessed_clues.each_with_index { |c, i|
        c_part = cksum io, c.length, c_part
        raise ParseError unless io.sysread(0x1) == "\x00"
      }
      # See above comment for conditional check here
      if @version == '1.3' && @notes.length > 0
        c_part = cksum io, @notes.length + 1, c_part
      end

      raise ChecksumError if \
        @masked_low_cksum[0] != (0x49 ^ (@cib_cksum & 0xff)) ||
        @masked_low_cksum[1] != (0x43 ^ (c_sol & 0xff)) ||
        @masked_low_cksum[2] != (0x48 ^ (c_grid & 0xff)) ||
        @masked_low_cksum[3] != (0x45 ^ (c_part & 0xff)) ||
        @masked_high_cksum[0] != (0x41 ^ ((@cib_cksum >> 8) & 0xff)) ||
        @masked_high_cksum[1] != (0x54 ^ ((c_sol >> 8) & 0xff)) ||
        @masked_high_cksum[2] != (0x45 ^ ((c_grid >> 8) & 0xff)) ||
        @masked_high_cksum[3] != (0x44 ^ ((c_part >> 8) & 0xff))
    end

    # Performs a checksum on the I/O over a specified region from whatever the
    # current position of the IO object is
    #
    # @param [IO] io the I/O object
    # @param [Integer] len the number of bytes to sum
    # @param [Integer] sum the initial value of the checksum
    #
    # @return [Integer] the checksum of the bytes
    def cksum io, len, sum = 0
      io.sysread(len).bytes.each { |byte|
        sum = sum & 0x1 == 1 ? (sum >> 1) + 0x8000 : sum >> 1;
        sum += byte
        sum &= 0xffff
      }

      sum
    end

  end
end
