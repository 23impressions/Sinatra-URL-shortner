# Generates a unique tiny alphanumeric string (kindof like TinyURL)
#
# This is a database model because we persist 1 column in 
# a table to keep track of the #last_slug generated.
#
class UniqueSLUG
  include DataMapper::Resource

  property :id,        Serial
  property :last_slug, String, :required => true

  # alphanumeric characters, case insensitive, stringified
  AVAILABLE_CHARACTERS = ( ('a'..'z').to_a + (0..9).to_a ).map {|char| char.to_s }

  class << self
    attr_accessor :reserved, :minimum_length
    alias reserved_slugs reserved
  end

  # Get the last slug generated (persisted)
  #
  # Used by UniqueSlug.next as the default seed
  #
  def self.last_slug
    begin
      first = UniqueSLUG.first
    rescue Exception => ex
      return nil if ex.message =~ /no such table: unique_slugs/ # database connection not initialized yet
    end
    if first
      first.last_slug
    else
      nil
    end
  end

  # Set the last slug (persisted)
  def self.last_slug= value
    first = UniqueSLUG.first
    first = UniqueSLUG.new unless first
    first.last_slug = value
    first.save
  end

  # Setter for UniqueSLUG.minimum_length
  #
  # Catches the rare exception where we try setting the 
  # minimum_length to something smaller than existing SLUGs
  #
  def self.minimum_length= length
    raise "Minimum length cannot be set to a length smaller than existing SLUGs" if UniqueSLUG.last_slug.to_s.length > length
    @minimum_length = length
  end

  UniqueSLUG.reserved       ||= %w( about blog new )
  UniqueSLUG.minimum_length ||= 3

  # Get the next available character, given a character
  #
  # ==== Parameters
  # <~to_s>:: The character that we want to find the *next* available character for
  # Object::  Value to return if the character given is the last available character.  Default: nil
  #
  # ==== Returns
  # String::
  #   The next available character or the second parameter, 
  #   return_if_last_character, if the character given is 
  #   the last available character.
  #
  # ==== Notes
  # Raises Exception if character provided doesn't exist in AVAILABLE_CHARACTERS
  #
  def self.next_available_character character, return_if_last_character = nil
    character = character.to_s
    index_of_character = AVAILABLE_CHARACTERS.index character
    raise "Invalid Character: #{ character.inspect }" unless index_of_character
    return return_if_last_character if character == AVAILABLE_CHARACTERS.last
    AVAILABLE_CHARACTERS[ index_of_character + 1 ]
  end

  # Get the next unique SLUG
  #
  # ==== Parameters
  # String:: Options seed value.  default: UniqueSlug....
  #
  # ==== Returns
  # String:: ...
  #
  # ==== Notes
  #
  # If a seed is passed, UniqueSLUG#last_slug will *NOT* be updated.
  #
  # If a seed is not passed, UniqueSLUG#last_slug will be used as 
  # the seed and then UniqueSLUG#last_slug will be updated.
  #
  def self.next seed = :use_last_slug
    update_last_slug = ( seed == :use_last_slug )
    seed = UniqueSLUG.last_slug if seed == :use_last_slug

    # start with first character if seed not given
    unless seed
      UniqueSLUG.last_slug = AVAILABLE_CHARACTERS.first * UniqueSLUG.minimum_length if update_last_slug
      return AVAILABLE_CHARACTERS.first * UniqueSLUG.minimum_length
    end

    seed = seed.to_s.strip.downcase

    # handle rare, special case where the minimum_length has been changed and it's 
    # longer than the last_slug ... because the minimum > the last one, we know that 
    # the new first slug (with the right minimum_length) hasn't been created yet
    if UniqueSLUG.minimum_length > seed.length
      UniqueSLUG.last_slug = AVAILABLE_CHARACTERS.first * UniqueSLUG.minimum_length if update_last_slug
      return AVAILABLE_CHARACTERS.first * UniqueSLUG.minimum_length
    end

    seed_characters = seed.split ''

    # the next character that should be implemented and
    # the spot it should go in, eg.
    #
    #   for 'aa' we should get [ 'b', 1 ] # b should go in spot 1
    #   for 'az' we should get [ 'b', 0 ] # b should go in spot 0
    #
    next_character_and_spot = nil

    seed_characters.reverse.each_with_index do |character, i|
      if next_available_character(character)
        next_character_and_spot = [ next_available_character(character), i ]
        break
      else
        next
      end
    end

    next_to_return = nil

    if next_character_and_spot
      
      # TODO fix the reverse stuff ... we don't need that
      seed_characters.reverse!
      next_character, spot = next_character_and_spot
      seed_characters[ spot ] = next_character
      # replace everything to the *right* of the replaced character ... (left cause reversed)
      if spot != 0
        (0..(spot - 1)).each do |index_to_replace|
          seed_characters[ index_to_replace ] = AVAILABLE_CHARACTERS.first
        end
      end
      seed_characters.reverse!
      next_to_return = seed_characters.join

    else
      # none of the characters had valid next_available_character, so increment the number of characters
      next_to_return = AVAILABLE_CHARACTERS.first * ( seed.length + 1 )
    end

    UniqueSLUG.last_slug = next_to_return if update_last_slug

    if UniqueSLUG.reserved_slugs.include? next_to_return
      next_to_return = UniqueSLUG.next
    end

    return next_to_return
  end

end
