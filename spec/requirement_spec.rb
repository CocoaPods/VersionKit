require File.expand_path('../spec_helper', __FILE__)

module VersionKit
  describe Requirement do

    #-------------------------------------------------------------------------#

    describe 'In general' do

      describe '#new' do
        it 'can be initialized with a version' do
          @subject = Requirement.new('1.0.0')
          @subject.operator.should == '='
          @subject.reference_version.should == '1.0.0'
        end

        it 'can be initialized with a non normalized version' do
          @subject = Requirement.new('1.0')
          @subject.operator.should == '='
          @subject.reference_version.should == '1.0.0'
        end

        it 'can be initialized with a version preceded by a space' do
          @subject = Requirement.new(' 1.0')
          @subject.operator.should == '='
          @subject.reference_version.should == '1.0.0'
        end

        it 'can be initialized with a given operator' do
          @subject = Requirement.new('!= 2.1.3')
          @subject.operator.should == '!='
          @subject.reference_version.should == '2.1.3'
        end

        it 'raises if initialized with an unsupported operator' do
          should.raise ArgumentError do
            Requirement.new('$ 1.0.0')
          end.message.should.match /Unsupported operator/
        end

        it 'raises if initialized with a non valid version' do
          should.raise ArgumentError do
            Requirement.new('!= 2.1-rc0')
          end.message.should.match /Malformed version/
        end

        it 'raises if the version is not provided' do
          should.raise ArgumentError do
            Requirement.new('= ')
          end.message.should.match /Malformed version/
        end
      end

      describe '#satisfied_by?' do
        it 'returns whether a version satisfies the `=` operator' do
          @subject = Requirement.new('= 2.1.0')
          @subject.should.be.satisfied_by?('2.1.0')
          @subject.should.be.satisfied_by?('2.1')
          @subject.should.be.not.satisfied_by?('2.2.0')
        end

        it 'returns whether a version satisfies the `!=` operator' do
          @subject = Requirement.new('!= 2.1.0')
          @subject.should.be.satisfied_by?('2.2.0')
          @subject.should.be.not.satisfied_by?('2.1.0')
          @subject.should.be.not.satisfied_by?('2.1')
        end

        it 'returns whether a version satisfies the `>` operator' do
          @subject = Requirement.new('> 2.1.0')
          @subject.should.be.satisfied_by?('2.2')
          @subject.should.not.be.satisfied_by?('2.1')
        end

        it 'returns whether a version satisfies the `<` operator' do
          @subject = Requirement.new('< 2.1.0')
          @subject.should.be.satisfied_by?('2.0')
          @subject.should.not.be.satisfied_by?('2.1')
          @subject.should.not.be.satisfied_by?('2.2')
        end

        it 'returns whether a version satisfies the `>=` operator' do
          @subject = Requirement.new('>= 2.1.0')
          @subject.should.be.satisfied_by?('2.2')
          @subject.should.be.satisfied_by?('2.1')
          @subject.should.not.be.satisfied_by?('2.0')
        end

        it 'returns whether a version satisfies the `<=` operator' do
          @subject = Requirement.new('<= 2.1.0')
          @subject.should.be.satisfied_by?('2.0')
          @subject.should.be.satisfied_by?('2.1')
          @subject.should.not.be.satisfied_by?('2.2')
        end

        it 'returns whether a version satisfies the `~>` operator' do
          @subject = Requirement.new('~> 2.1.0')
          @subject.should.be.satisfied_by?('2.1')
          @subject.should.be.satisfied_by?('2.1.0')
          @subject.should.be.satisfied_by?('2.1.5')
          @subject.should.be.not.satisfied_by?('2.2.0')
          @subject.should.be.not.satisfied_by?('2.2')
        end

        it 'returns whether a version satisfies the `~>` operator ' \
           'on a non-patch reference version' do
          @subject = Requirement.new('~> 2.1')
          @subject.should.be.satisfied_by?('2.1')
          @subject.should.be.satisfied_by?('2.1.0')
          @subject.should.be.satisfied_by?('2.1.5')
          @subject.should.be.satisfied_by?('2.2.0')
          @subject.should.be.satisfied_by?('2.2')
          @subject.should.not.be.satisfied_by?('2.0.1')
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Object methods' do
      describe '#to_s' do
        it 'returns the string representation' do
          @subject = Requirement.new('!= 2.1.0')
          @subject.to_s.should == '!= 2.1.0'
        end

        it 'normalized the version' do
          @subject = Requirement.new('!= 2.1')
          @subject.to_s.should == '!= 2.1.0'
        end
      end

      describe '#<=>' do
        it 'allows sorting' do
          list = [Requirement.new('> 2.1'), Requirement.new('< 3.0')]
          list.sort.map(&:to_s).should == ['< 3.0.0', '> 2.1.0']
        end
      end

      describe 'hash' do
        it 'returns the hash' do
          Requirement.new('> 2.1').hash.class.should == Fixnum
        end
      end
    end

    #-------------------------------------------------------------------------#

  end
end
