require 'pry'

class Board
  INITIAL_MARKER = ' '
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  def initialize
    @squares = {}
    reset
  end

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def threat?(current_marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if threat_two_identical_markers?(squares, current_marker)
        squares.each do |square|
          return true if square.marker == INITIAL_MARKER
        end
      end
    end
    false
  end

  def advantage?(current_marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if advantage_two_identical_markers?(squares, current_marker)
        squares.each do |square|
          return true if square.marker == INITIAL_MARKER
        end
      end
    end
    false
  end

  def locate_advantage(current_marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if advantage_two_identical_markers?(squares, current_marker)
        squares.each do |square|
          if square.marker == INITIAL_MARKER
            return line[squares.find_index(square)]
          end
        end
      end
    end
  end

  def five_open?
    @squares[5].marker == INITIAL_MARKER
  end

  def locate_threat(current_marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if threat_two_identical_markers?(squares, current_marker)
        squares.each do |square|
          return line[squares.find_index(square)] if square.marker == INITIAL_MARKER
        end
      end
    end
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end

  def advantage_two_identical_markers?(squares, current_marker)
    if current_marker == "X"
      markers = squares.select(&:human_marked?).collect(&:marker)
      return false if markers.size != 2
    elsif current_marker == "O"
      markers = squares.select(&:computer_marked?).collect(&:marker)
      return false if markers.size != 2
    end
    true
  end

  def threat_two_identical_markers?(squares, current_marker)
    if current_marker != "O"
      markers = squares.select(&:computer_marked?).collect(&:marker)
      return false if markers.size != 2
    elsif current_marker != 'X'
      markers = squares.select(&:human_marked?).collect(&:marker)
      return false if markers.size != 2
    end
    true
  end
end

class Square
  INITIAL_MARKER = " "
  HUMAN_MARKER = "X"
  COMPUTER_MARKER = 'O'

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def human_marked?
    marker == HUMAN_MARKER
  end

  def computer_marked?
    marker == COMPUTER_MARKER
  end
end

class Player
  attr_accessor :name, :marker

  @@holder_for_marker = nil

  def initialize(marker)
    @marker = marker
    choose_name
    choose_marker
  end

  def choose_name
    system 'clear'
    answer = nil
    if @marker == 'X'
      loop do
        puts "Please choose your name"
        answer = gets.chomp.strip
        break if !answer.empty?
        puts "Please provide a valid name"
      end
      self.name = answer
    else
      self.name = %w(R2D2 Forty-Two C3PO).sample
    end
  end

  def choose_marker
    if marker == 'X'
      answer = nil
      loop do
        puts " "
        puts "Please choose your marker (X or O)"
        answer = gets.chomp
        break if %w(x o X O).include?(answer)
        puts "Must provide valid input!"
      end
      self.marker = answer.upcase
      @@holder_for_marker = answer.upcase
    elsif marker == "O"
      self.marker = 'X' if @@holder_for_marker == "O"
      self.marker = 'O' if @@holder_for_marker == "X"
    end
  end
end

class TTTGame
  X_MARKER = "X"
  O_MARKER = "O"
  FIRST_TO_MOVE = X_MARKER

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(X_MARKER)
    @computer = Player.new(O_MARKER)
    @current_marker = FIRST_TO_MOVE
    @human_score = 0
    @computer_score = 0
    @chosen_marker_holder = nil
  end

  def play
    who_first
    loop do
      reset
      reset_scores
      clear
      loop do
        clear
        display_welcome_message
        display_board

        loop do
          current_player_moves
          break if board.someone_won? || board.full?
          clear_screen_and_display_board
        end

        display_result
        break if five?
        continue
        reset
        display_play_again_message
      end
      clear_screen_and_display_board
      grand_winner
      break unless play_again?
    end
    display_goodbye_message
  end

  private

  def who_first
    answer = nil
    loop do
      puts "Would you like to go first? (Y/N)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Please provide a valid input (Y or N)!"
    end
    if answer == 'y'
      @current_marker_holder = answer
      @current_marker = human.marker
    else
      @current_marker_holder = answer
      @current_marker = computer.marker
    end
  end

  def reset_scores
    @computer_score = 0
    @human_score = 0
  end

  def grand_winner
    if @computer_score == 5
      puts "#{computer.name} won it all!"
    else
      puts "#{human.name} won it all!"
    end
  end

  def continue
    loop do
      puts "Press Enter to continue to the next round:"
      x = gets.chomp
      break if x == ''
      puts "Sorry, you must ONLY press Enter"
    end
  end

  def display_score
    puts "#{human.name} => Rounds won: #{@human_score}".rjust(70)
    puts "#{computer.name} => Rounds won: #{@computer_score}".rjust(70)
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def display_board
    puts "You're an #{human.marker}. #{computer.name} is an #{computer.marker}."
    display_score
    board.draw
    puts ""
  end

  def join(unmarked_keys, comma=', ', final='or')
    array = unmarked_keys
    case unmarked_keys.size
    when 0 then ''
    when 1 then unmarked_keys.first
    when 2 then unmarked_keys.join(" #{final} ")
    else
      array[-1] = final + " " + array[-1].to_s
      array.join(comma)
    end
  end

  def human_moves
    puts "Choose a square (#{join(board.unmarked_keys)}): "
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    if board.five_open?
      board[5] = computer.marker
    elsif board.advantage?(computer.marker)
      board[board.locate_advantage(computer.marker)] = computer.marker
    elsif board.threat?(computer.marker)
      board[board.locate_threat(computer.marker)] = computer.marker
    else
      board[board.unmarked_keys.sample] = computer.marker
    end
  end

  def current_player_moves
    if @current_marker == human.marker
      human_moves
      @current_marker = computer.marker
    else
      computer_moves
      @current_marker = human.marker
    end
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won!"
      @human_score += 1
    when computer.marker
      puts "#{computer.name} won!"
      @computer_score += 1
    else
      puts "It's a tie!"
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def five?
    @computer_score == 5 ||
      @human_score == 5
  end

  def clear
    system "clear"
  end

  def reset
    board.reset
    if @current_marker_holder == 'y'
      @current_marker = human.marker
    else
      @current_marker = computer.marker
    end
    clear
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end
end

game = TTTGame.new
game.play
