require File.expand_path('../spec_helper', __FILE__)

module VersionKit
  describe RequirementList do

    #-------------------------------------------------------------------------#

    describe 'In general' do
      describe '#new' do
        it 'can be initialized without requirements' do
          @subject = RequirementList.new
          @subject.requirements.should == []
        end

        it 'can be initialized with requirements' do
          @subject = RequirementList.new([Requirement.new('> 1.2')])
          @subject.requirements.map(&:to_s).should == ['> 1.2.0']
        end

        it 'can be initialized with a single requirement' do
          @subject = RequirementList.new(Requirement.new('> 1.2'))
          @subject.requirements.map(&:to_s).should == ['> 1.2.0']
        end

        it 'can be initialized with string requirements' do
          @subject = RequirementList.new(['> 1.2'])
          @subject.requirements.map(&:to_s).should == ['> 1.2.0']
        end

        it 'raises if unable to handle normalize the given requirements' do
          should.raise ArgumentError do
            RequirementList.new(['> 1.2', Array.new])
          end
        end
      end

      describe '#add_requirement' do
        it 'allows to add requirements' do
          @subject = RequirementList.new
          @subject.add_requirement(Requirement.new('1.2'))
          @subject.requirements.map(&:to_s).should == ['= 1.2.0']
        end

        it 'allows to add requirements expressed as strings' do
          @subject = RequirementList.new
          @subject.add_requirement('> 1.2')
          @subject.requirements.map(&:to_s).should == ['> 1.2.0']
        end
      end

      describe '#satisfied_by' do
        it 'returns if all the requirements are satisfied by a version' do
          @subject = RequirementList.new
          @subject.add_requirement(Requirement.new('> 1.2'))
          @subject.add_requirement(Requirement.new('< 3.0'))
          @subject.should.be.satisfied_by('1.3')
          @subject.should.not.be.satisfied_by('1.2')
          @subject.should.not.be.satisfied_by('3.1')
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Object methods' do

      before do
        @subject = RequirementList.new
        @subject.add_requirement(Requirement.new('> 1.2'))
        @subject.add_requirement(Requirement.new('< 3.0'))
      end

      describe '#to_s' do
        it 'returns the string representation' do
          @subject.to_s.should == '> 1.2.0, < 3.0.0'
        end
      end

      describe 'hash' do
        it 'returns the hash' do
          @subject.hash.class.should == Integer
        end
      end

      describe '#==' do
        it 'is equal to another with the same requirements' do
          @subject.should == RequirementList.new(['> 1.2', '< 3.0'])
          @subject.should == RequirementList.new(['> 1.2.0', '< 3.0.0'])
        end

        it 'is not equal to another with different requirements' do
          @subject.should.not == RequirementList.new(['> 1.2', '< 3.1'])
        end
      end
    end

    #-------------------------------------------------------------------------#

  end
end
