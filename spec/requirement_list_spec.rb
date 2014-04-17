require File.expand_path('../spec_helper', __FILE__)

module VersionKit
  describe RequirementList do

    #-------------------------------------------------------------------------#

    describe 'In general' do
      describe '#new' do
        it 'can be initialized without requirements' do
          sut = RequirementList.new
          sut.requirements.should == []
        end

        it 'can be initialized with requirements' do
          sut = RequirementList.new([Requirement.new('> 1.2')])
          sut.requirements.map(&:to_s).should == ['> 1.2.0']
        end

        it 'can be initialized with a single requirement' do
          sut = RequirementList.new(Requirement.new('> 1.2'))
          sut.requirements.map(&:to_s).should == ['> 1.2.0']
        end

        it 'can be initialized with string requirements' do
          sut = RequirementList.new(['> 1.2'])
          sut.requirements.map(&:to_s).should == ['> 1.2.0']
        end

        it 'raises if unable to handle normalize the given requirements' do
          should.raise ArgumentError do
            RequirementList.new(['> 1.2', Array.new])
          end
        end
      end

      describe '#add_requirement' do
        it 'allows to add requirements' do
          sut = RequirementList.new
          sut.add_requirement(Requirement.new('1.2'))
          sut.requirements.map(&:to_s).should == ['= 1.2.0']
        end

        it 'allows to add requirements expressed as strings' do
          sut = RequirementList.new
          sut.add_requirement('> 1.2')
          sut.requirements.map(&:to_s).should == ['> 1.2.0']
        end
      end

      describe '#satisfied_by' do
        it 'returns if all the requirements are satisfied by a version' do
          @sut = RequirementList.new
          @sut.add_requirement(Requirement.new('> 1.2'))
          @sut.add_requirement(Requirement.new('< 3.0'))
          @sut.should.be.satisfied_by('1.3')
          @sut.should.not.be.satisfied_by('1.2')
          @sut.should.not.be.satisfied_by('3.1')
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Object methods' do

      before do
        @sut = RequirementList.new
        @sut.add_requirement(Requirement.new('> 1.2'))
        @sut.add_requirement(Requirement.new('< 3.0'))
      end

      describe '#to_s' do
        it 'returns the string representation' do
          @sut.to_s.should == '> 1.2.0, < 3.0.0'
        end
      end

      describe 'hash' do
        it 'returns the hash' do
          @sut.hash.class.should == Fixnum
        end
      end
    end

    #-------------------------------------------------------------------------#

  end
end
