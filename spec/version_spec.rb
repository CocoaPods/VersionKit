require File.expand_path('../spec_helper', __FILE__)

module VersionKit
  describe Version do

    #-------------------------------------------------------------------------#

    describe 'In general' do

      it 'raises if initialized with a not valid string representation' do
        should.raise ArgumentError do
          Version.new('v1')
        end.message.should.match /Malformed version string/
      end

      before do
        @sut = Version.new('1.2.0-alpha1.0+20130313144700')
      end

      it 'returns the major, minor and patch version' do
        @sut.number_component.should == [1, 2, 0]
      end

      it 'returns the pre-release identifiers' do
        @sut.pre_release_component.should == ['alpha1', 0]
      end

      it 'returns the build identifiers' do
        @sut.build_component.should == [20_130_313_144_700]
      end

    end

    #-------------------------------------------------------------------------#

    describe 'Class methods' do

      describe '::valid?' do
        it 'accepts a normal version number' do
          Version.valid?('1.9.0').should.be.true
          Version.valid?('1.20.145').should.be.true
        end

        it 'accepts Pre-release components' do
          Version.valid?('1.0.0-alpha').should.be.true
          Version.valid?('1.0.0-alpha.1').should.be.true
          Version.valid?('1.0.0-0.3.7').should.be.true
          Version.valid?('1.0.0-x.7.z.92').should.be.true
          Version.valid?('1.0.0-rc1').should.be.true
        end

        it 'accepts versions including Build component' do
          Version.valid?('1.0.0-alpha+001').should.be.true
          Version.valid?('1.0.0+20130313144700').should.be.true
          Version.valid?('1.0.0-beta+exp.sha.5114f85').should.be.true
          Version.valid?('1.2.3+0000.build').should.be.true
        end

        it 'rejects non numerical characters in the Number component' do
          Version.valid?('v0.0.1').should.be.false
          Version.valid?('0.0.1alpha').should.be.false
          Version.valid?('0.0 .1').should.be.false
          Version.valid?('0.1+.1').should.be.false
        end

        it 'rejects versions an identifier count different than 3' do
          Version.valid?('1').should.be.false
          Version.valid?('0.1').should.be.false
          Version.valid?('0.1.0.3').should.be.false
          Version.valid?('0.1-alpha').should.be.false
        end
      end

      describe '::lenient_new' do
        it 'supports versions with one identifier' do
          Version.lenient_new('1').to_s.should == '1.0.0'
        end

        it 'supports versions with two identifiers' do
          Version.lenient_new('1.0').to_s.should == '1.0.0'
        end
      end

    end

    #-------------------------------------------------------------------------#

    describe 'Object methods' do

      before do
        @sut = Version.new('1.2.3')
      end

      it 'returns the string representation' do
        @sut.to_s.should == '1.2.3'
      end

      it 'returns a string suitable for debugging' do
        @sut.inspect.should == '<VersionKit::Version 1.2.3>'
      end

      it 'returns whether it is equal to another version' do
        Version.new('1.2.3').should == Version.new('1.2.3')
        Version.new('1.2.3').should.not == Version.new('1.2.4')
      end

      describe 'eql?' do
        it 'returns true for if the version are the same' do
          other = Version.new('1.2.3')
          @sut.should.eql(other)
        end

        it 'returns false if the version are not the same' do
          other = Version.new('1.2.4')
          @sut.should.not.eql(other)
        end
      end

      it 'returns the hash' do
        @sut.hash.should == '1.2.3'.hash
        @sut.hash.should == Version.new('1.2.3').hash
      end

      describe '<=>' do
        it 'returns nil if compared to an object of another class' do
          (@sut <=> 'String').should.be.nil
        end

        it 'always compares major, minor, and patch versions numerically' do
          v1 = Version.new('1.0.0')
          v2 = Version.new('2.0.0')
          v3 = Version.new('2.1.0')
          v4 = Version.new('2.1.1')
          (v1 < v2).should.be.true
          (v2 < v3).should.be.true
          (v3 < v4).should.be.true
        end

        it 'assigns lower precedence to Pre-release components' do
          v1 = Version.new('1.0.0-alpha')
          v2 = Version.new('1.0.0')
          (v1 < v2).should.be.true
        end

        it 'handles pre-release fields properly' do
          v1 = Version.new('1.0.0-alpha')
          v2 = Version.new('1.0.0-alpha.1')
          v3 = Version.new('1.0.0-alpha.beta')
          v4 = Version.new('1.0.0-beta')
          v5 = Version.new('1.0.0-beta.2')
          v6 = Version.new('1.0.0-beta.11')
          v7 = Version.new('1.0.0-rc.1')
          v8 = Version.new('1.0.0')
          (v1 < v2).should.be.true
          (v2 < v3).should.be.true
          (v3 < v4).should.be.true
          (v4 < v5).should.be.true
          (v5 < v6).should.be.true
          (v6 < v7).should.be.true
          (v7 < v8).should.be.true

          # Testing the symmetrical code path
          (v2 > v1).should.be.true
          (v3 > v2).should.be.true
          (v8 > v7).should.be.true
        end

        it "doesn't takes into account build fields" do
          v1 = Version.new('1.0.0-alpha+20130707')
          v2 = Version.new('1.0.0-alpha')
          (v1 <=> v2).should == 0
        end
      end

    end

    #-------------------------------------------------------------------------#

    describe 'Semantic Versioning' do

      it 'identifies release versions' do
        version = Version.new('1.0.0')
        version.should.not.be.pre_release
      end

      it 'identifies Pre-release components' do
        version = Version.new('1.0.0-x.7.z.92')
        version.should.be.pre_release
      end

      it 'returns the major version' do
        Version.new('1.9.0').major_version.should == 1
        Version.new('1.0.0-alpha').major_version.should == 1
      end

      it 'returns the minor identifier' do
        Version.new('1.9.0').minor.should == 9
        Version.new('1.4.0-alpha').minor.should == 4
      end

      it 'returns the patch identifier' do
        Version.new('1.9.4').patch.should == 4
        Version.new('1.0.1-alpha').patch.should == 1
      end

      it 'returns the release version' do
        Version.new('1.9.4').release_version.to_s.should == '1.9.4'
        Version.new('1.9.4-rc0').release_version.to_s.should == '1.9.4'
      end

      it 'returns the optimistic recommendation' do
        Version.new('1.9.4').optimistic_recommendation.should == '~> 1.9'
        Version.new('0.9.4').optimistic_recommendation.should == '~> 0.9.4'
        Version.new('0.9.4-rc0').optimistic_recommendation.should == '~> 0.9.4'
      end
    end
  end
end
