require File.expand_path('../spec_helper', __FILE__)

module VersionKit
  describe Version do
    describe 'Class methods' do
      before do
        @subject = Version
      end

      describe '::new' do
        it 'can be initialized with a string' do
          result = @subject.new('1.2.0-alpha1.0+20130313144700')
          result.to_s.should == '1.2.0-alpha1.0+20130313144700'
        end

        it 'can be initialized with any object convertible to a string' do
          result = @subject.new(@subject.new('1.2.0-alpha1.0+20130313144700'))
          result.to_s.should == '1.2.0-alpha1.0+20130313144700'
        end

        it 'leniently accepts strings with major versions' do
          @subject.new('1').to_s.should == '1.0.0'
        end

        it 'leniently accepts strings with minor versions' do
          @subject.new('1.0').to_s.should == '1.0.0'
        end

        it 'raises if initialized with a non valid string representation' do
          should.raise ArgumentError do
            @subject.new('v1+build_metadata-version')
          end.message.should.match /Malformed version/
        end

        it 'populates the components of the version' do
          result = @subject.new('1.2.0-alpha1.0+20130313144700')
          result.components.should ==
            [[1, 2, 0], ['alpha1', 0], [20_130_313_144_700]]
        end

        it 'can be initialized with the components' do
          components = [[1, 2, 0], ['alpha1', 0], [20_130_313_144_700]]
          result = @subject.new(components)
          result.to_s.should == '1.2.0-alpha1.0+20130313144700'
        end

        it 'leniently accepts components with major versions' do
          @subject.new([[1]]).to_s.should == '1.0.0'
        end

        it 'leniently accepts components with minor versions' do
          @subject.new([[1, 0]]).to_s.should == '1.0.0'
        end

        it 'raises if initialized with a non valid components' do
          should.raise ArgumentError do
            @subject.new(['alpha1'])
          end.message.should.match /Malformed version components/
        end
      end

      describe '::normalize' do
        it 'defaults to 0 the patch version if missing' do
          @subject.normalize('1.0').should == '1.0.0'
        end

        it 'defaults to 0 the minor version if missing' do
          @subject.normalize('1').should == '1.0.0'
        end

        it 'returns the given value if the normalization is not safe' do
          @subject.normalize('1-alpha').should == '1-alpha'
        end
      end

      describe '::normalize_components' do
        it 'defaults to 0 the patch version if missing' do
          @subject.normalize_components([[1, 0], [], []]).should ==
            [[1, 0, 0], [], []]
        end

        it 'defaults to 0 the minor version if missing' do
          @subject.normalize_components([[1], [], []]).should ==
            [[1, 0, 0], [], []]
        end

        it 'includes an empty number component if missing' do
          @subject.normalize_components([[1, 0, 0]]).should ==
            [[1, 0, 0], [], []]
        end

        it 'includes an empty pre-release component if missing' do
          @subject.normalize_components([[1, 0, 0], []]).should ==
            [[1, 0, 0], [], []]
        end

        it 'returns the given value if the normalization is not safe' do
          @subject.normalize_components('1-alpha').should == '1-alpha'
        end
      end

      describe '::valid?' do
        it 'accepts a normal version number' do
          @subject.valid?('1.9.0').should.be.true
          @subject.valid?('1.20.145').should.be.true
        end

        it 'accepts pre-release components' do
          @subject.valid?('1.0.0-alpha').should.be.true
          @subject.valid?('1.0.0-alpha.1').should.be.true
          @subject.valid?('1.0.0-0.3.7').should.be.true
          @subject.valid?('1.0.0-x.7.z.92').should.be.true
          @subject.valid?('1.0.0-rc1').should.be.true
        end

        it 'accepts versions including Build component' do
          @subject.valid?('1.0.0-alpha+001').should.be.true
          @subject.valid?('1.0.0+20130313144700').should.be.true
          @subject.valid?('1.0.0-beta+exp.sha.5114f85').should.be.true
          @subject.valid?('1.2.3+0000.build').should.be.true
        end

        it 'rejects non numerical characters in the Number component' do
          @subject.valid?('v0.0.1').should.be.false
          @subject.valid?('0.0.1alpha').should.be.false
          @subject.valid?('0.0 .1').should.be.false
          @subject.valid?('0.1+.1').should.be.false
        end

        it 'rejects versions with an identifier count different than 3' do
          @subject.valid?('1').should.be.false
          @subject.valid?('0.1').should.be.false
          @subject.valid?('0.1.0.3').should.be.false
          @subject.valid?('0.1-alpha').should.be.false
        end
      end
    end

    describe 'Instance methods' do
      before do
        @subject = Version.new('1.2.0-alpha1.0+20130313144700')
      end

      it 'returns the number component' do
        @subject.number_component.should == [1, 2, 0]
      end

      it 'returns the pre-release component' do
        @subject.pre_release_component.should == ['alpha1', 0]
      end

      it 'returns the build component' do
        @subject.build_component.should == [20_130_313_144_700]
      end

      it 'returns the major version' do
        Version.new('1.9.0').major_version.should == 1
        Version.new('1.0.0-alpha').major_version.should == 1
      end

      it 'returns the minor version' do
        Version.new('1.9.0').minor.should == 9
        Version.new('1.4.0-alpha').minor.should == 4
      end

      it 'returns the patch version' do
        Version.new('1.9.4').patch.should == 4
        Version.new('1.0.1-alpha').patch.should == 1
      end

      it 'returns whether it is a pre_release version' do
        version = Version.new('1.0.0')
        version.should.not.be.pre_release
        version = Version.new('1.0.0-x.7.z.92')
        version.should.be.pre_release
      end

      it 'returns the string representation' do
        @subject.to_s.should == '1.2.0-alpha1.0+20130313144700'
      end

      it 'returns a string suitable for debugging' do
        @subject.inspect.should ==
          '<VersionKit::Version 1.2.0-alpha1.0+20130313144700>'
      end

      describe '#==' do
        it 'returns whether it is equal to another version' do
          @subject.should == Version.new('1.2.0-alpha1.0+20130313144700')
          @subject.should.not == Version.new('1.2.0')
        end

        it 'can be compared to a string' do
          @subject.should == '1.2.0-alpha1.0+20130313144700'
          @subject.should.not == '1.2.0'
        end
      end

      describe '#eql?' do
        it 'returns true if the version are the same' do
          other = Version.new('1.2.0-alpha1.0+20130313144700')
          @subject.should.eql(other)
        end

        it 'returns false if the version are not the same' do
          other = Version.new('1.2.0')
          @subject.should.not.eql(other)
        end
      end

      describe '#hash?' do
        it 'returns the hash' do
          @subject.hash.should ==
            Version.new('1.2.0-alpha1.0+20130313144700').hash
        end

        it 'uses a different hash of the string representation' do
          @subject.hash.should.not == '1.2.0-alpha1.0+20130313144700'.hash
        end
      end

      describe '#<=>' do
        it 'returns nil if compared to an object of another class' do
          (@subject <=> 'String').should.be.nil
        end

        it 'compares major, minor, and patch versions numerically' do
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
  end
end
