require File.dirname(__FILE__) + '/spec_helper'

#
# make sure our slugs are generated the way 
# we expect them to be generated
#
# this is very much like TinyURL's algorithm
#
describe UniqueSLUG do

  before do
    UniqueSLUG.all.destroy
    @default_minimum_length = UniqueSLUG.minimum_length
    UniqueSLUG.minimum_length = 1 # for this spec
  end

  after do
    UniqueSLUG.all.destroy
    UniqueSLUG.minimum_length = @default_minimum_length # reset
  end

  { 
    nil    => 'a',
    'a'    => 'b',
    :a     => 'b',
    'A'    => 'b',
    ' A '  => 'b',
    'b'    => 'c',
    'z'    => '0',
    9      => 'aa',
    'aa'   => 'ab',
    'az'   => 'a0',
    'a9'   => 'ba',
    'aa9'  => 'aba',
    'abcd' => 'abce',
    '9999' => 'aaaaa'
  }.
    each do |seed, slug|
      it "if seed is #{ seed.inspect } next slug should be #{ slug.inspect }" do
        UniqueSLUG.next(seed).should == slug
      end
    end

  it 'should keep track of the last slug so #next works without a seed' do
    UniqueSLUG.all.destroy
    UniqueSLUG.last_slug.should be_nil
    
    UniqueSLUG.next.should == 'a'
    UniqueSLUG.last_slug.should == 'a'

    UniqueSLUG.last_slug = 'abcd'
    UniqueSLUG.last_slug.should == 'abcd'
    UniqueSLUG.next.should == 'abce'
    UniqueSLUG.last_slug.should == 'abce'
  end

  it 'should not generate slugs that match reserved slugs' do
    UniqueSLUG.reserved = %w( )
    UniqueSLUG.last_slug = 'abous'
    UniqueSLUG.next.should == 'about'

    UniqueSLUG.reserved = %w( about )
    UniqueSLUG.last_slug = 'abous'
    UniqueSLUG.next.should == 'abouu' # abou[t] is skipped and we get abou[u]

    # in the rare case that 2 reserved words are in a row, they should both be skipped (or more than 2)
    UniqueSLUG.reserved = %w( about abouu abouv ) # should skip all the way to abouw
    UniqueSLUG.last_slug = 'abous'
    UniqueSLUG.next.should == 'abouw'
  end

  it 'should have a minumum length' do
    UniqueSLUG.minimum_length = 2
    UniqueSLUG.next.should == 'aa'

    UniqueSLUG.minimum_length = 4
    UniqueSLUG.next.should == 'aaaa'
    UniqueSLUG.next.should == 'aaab'

    UniqueSLUG.minimum_length = 5
    UniqueSLUG.next.should == 'aaaaa'
    UniqueSLUG.next.should == 'aaaab'

    lambda { UniqueSLUG.minimum_length = 2 }.should raise_error(/cannot be set/)
  end

end
