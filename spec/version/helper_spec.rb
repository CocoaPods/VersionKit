require File.expand_path('../../spec_helper', __FILE__)

module VersionKit
  describe Version::Helper do
    before do
      @sut = Version::Helper
    end

    describe 'bump' do
      it 'bumps the major component' do
        @sut.bump('1.2.3-rc.1', 0).should == '2.0.0'
      end

      it 'bumps the minor component' do
        @sut.bump('1.2.3-rc.1', 1).should == '1.3.0'
      end

      it 'bumps the patch component' do
        @sut.bump('1.2.3-rc.1', 2).should == '1.2.4'
      end

      it 'returns version instances' do
        @sut.bump('1.2.3-rc.1', 0).class.should == Version
      end

      it 'handles a string version' do
        @sut.bump('1.2.3-rc.1', 0).should == '2.0.0'
      end

      it 'handles a version instance' do
        @sut.bump(Version.new('1.2.3-rc.1'), 0).should == '2.0.0'
      end
    end

    describe 'next_major' do
      it 'bumps the major component' do
        @sut.next_major('1.2.3-rc.1').should == '2.0.0'
      end
    end

    describe 'next_minor' do
      it 'bumps the minor component' do
        @sut.next_minor('1.2.3-rc.1').should == '1.3.0'
      end
    end

    describe 'next_patch' do
      it 'bumps the patch component' do
        @sut.next_patch('1.2.3-rc.1').should == '1.2.4'
      end
    end

    describe 'next_pre_release' do
      it 'returns nil if no pre-release information is present' do
        @sut.next_pre_release('1.2.3').should.be.nil
      end

      it 'returns nil if the pre-release components are only letters' do
        @sut.next_pre_release('1.2.3-alpha').should.be.nil
      end

      it 'handles a single numeric pre-release component' do
        @sut.next_pre_release('1.2.3-1').should == '1.2.3-2'
      end

      it 'handles multiple pre-release components' do
        @sut.next_pre_release('1.2.3-rc.1').should == '1.2.3-rc.2'
      end

      it 'handles a pre-release component terminating in a number' do
        @sut.next_pre_release('1.2.3-rc1').should == '1.2.3-rc2'
      end
    end

    describe 'next_versions' do
      it 'returns the list of next available versions' do
        result = @sut.next_versions('1.2.3-rc.1')
        result.should == ['2.0.0', '1.3.0', '1.2.4', '1.2.3-rc.2']
      end
    end

    describe 'valid_next_version' do
      it 'accepts a valid next version' do
        @sut.valid_next_version?('1.2.3-rc.1', '1.3.0').should.be.true
      end

      it 'rejects a version which is not a valid next one' do
        @sut.valid_next_version?('1.2.3-rc.1', '1.3.3').should.be.false
      end
    end
  end
end
