class Hangman
  attr_reader :guesser, :referee, :board

  CHANCES = 10

  def initialize(players)
    @guesser = players[:guesser]
    @referee = players[:referee]
  end

  def setup
    length = @referee.pick_secret_word
    @guesser.register_secret_length(length)
    @board = Array.new(length, "_")
  end

  def take_turn
    resp = @guesser.guess(@board)
    indexes = @referee.check_guess(resp)
    @guesser.handle_response(resp,indexes)
    update_board(resp,indexes)
    puts "Secret word: #{@board.join}"
  end

  def update_board(letter,indexes)
    unless indexes.empty?
      @board = @board.each_with_index.map do |el,i|
        indexes.include?(i) ? letter : el
      end
    end
    @board
  end

  def game_over?
    is_over = true
    @board.each do |el|
      is_over = false if el == "_"
    end
    is_over
  end

  def play
    remaining_chances = CHANCES
    until game_over? || remaining_chances == 0
      take_turn
      remaining_chances -= 1 unless @guesser.response_ping
      puts "The guesser has #{remaining_chances} remaining\n"
    end
    if remaining_chances > 0
      puts "\nThe guesser wins!"
      puts "Secret word: #{@board.join}\n"
    else
      puts "\nThe guesser loses!"
      puts "Secret word: #{@referee.secret_word}\n"
    end
  end
end

class ComputerPlayer
  attr_reader :pattern, :secret_word, :response_ping

  def initialize(dictionary)
    @alphabet = ('a'..'z').to_a
    @dictionary = dictionary
    @letter_counts = Hash.new(0)
    @c_guesses = []
  end

  ##### COMP REFEREE MOVES ######

  def pick_secret_word
    @secret_word = @dictionary.sample
    @secret_word.length
  end

  def check_guess(char)
    @secret_word.each_char.with_index.map { |el, i| el == char ? i : nil }.compact
  end

  def handle_response(char, indexes)
    @response_ping = false
    @response_ping = true unless indexes.empty?
    @letter_counts[char] = indexes.length
    indexes.each do |idx|
      @pattern[idx] = char
    end
  end

  ##### COMP GUESSER MOVES #####
  def register_secret_length(given_length)
    @pattern = '.' * given_length
    @length = given_length
  end

  def candidate_words
    test_words = @dictionary.select { |word| word.length == @length }
    final_words = []
    test_words.each do |word|
      valid_count = @letter_counts.keys.all? { |key| word.count(key) == @letter_counts[key] }
      matches_options = word =~ /#{@pattern}/
      final_words << word if valid_count && matches_options
    end
    final_words
  end

  def guess(board)
    max_letter = Hash.new(0)
    candidate_words.each do |el|
      el.each_char do |ch|
        max_letter[ch] += 1
      end
    end
    candidate_letters = max_letter.to_a.sort { |a, b| a[1] <=> b[1] }

    # If board is nill
    if board.all?(&:nil?)
      max_result = candidate_letters.last.first
      @c_guesses.push(max_result)
      max_result

    # If there are guesses
    else
      while @c_guesses.include?(candidate_letters.last.first) || board.include?(candidate_letters.last.first)
        candidate_letters.pop
      end
      max_result = candidate_letters.last.first
      @c_guesses.push(max_result)
      max_result
    end
  end
end

class HumanPlayer < ComputerPlayer

attr_reader :pattern, :response_ping, :secret_word

  def initialize
    @u_guesses = []
    @alphabet = ('a'..'z').to_a
    @letter_counts = Hash.new(0)
  end

  ##### HUMAN REFEREE MOVES ######

  def pick_secret_word
    puts 'What is your secret word?'
    u_input = gets.chomp
    @secret_word = u_input
    @secret_word.length
  end

  def check_guess(char)
    puts "The computer guesses \"#{char}\", is this letter in your word? Reply \"y\" or \"n\"."
    u_input = gets.chomp
    if u_input == "y"
    @secret_word.each_char.with_index.map { |el, i| el == char ? i : nil }.compact
    else
    puts "Okay, the computer will guess again"
    []
    end
  end


  ##### HUMAN GUESSER MOVES #####

  def guess(board)
    puts "Which letter would you like to guess? You may also enter \"rg\" for random guess\n"
    u_input = gets.chomp
    if u_input == 'rg'
      rand_letter = @alphabet.sample
      rand_letter = @alphabet.sample unless @u_guesses.include?(rand_letter)
      @u_guesses << rand_letter
      puts "You randomly guessed #{rand_letter}!"
    else
      while @u_guesses.include?(u_input)
        puts "This letter was already selected! Pick another!\n"
        puts "Here are your chosen letters #{@u_guesses}"
        u_input = gets.chomp
      end
      @u_guesses << u_input
    end
    u_input
  end
end


if __FILE__ == $PROGRAM_NAME

  comp_dictionary = File.readlines("./dictionary.txt").map(&:chomp)

  puts 'Welcome to Hangman!'
  puts "\nWould you like to guess letters or choose the words for the computer to guess? Type \"human\" to guess or \"comp\" for the computer to guess.\n"
  u_input_start = gets.chomp.downcase

  if u_input_start == 'human'
    puts "Great! The computer has chosen a secret word, guess one letter at a time. The program will let you know if you've already chosen a letter."

    guessing_player = HumanPlayer.new
    reffing_player = ComputerPlayer.new(comp_dictionary)

  else
    puts 'Alright! The computer will guess and narrow down letters in your word without knowing the word itself.'

    guessing_player = ComputerPlayer.new(comp_dictionary)
    reffing_player = HumanPlayer.new

  end

  game = Hangman.new(guesser: guessing_player, referee: reffing_player)
  game.setup
  game.play
end
