require File.expand_path('../spec_helper', __FILE__)

module StdVer
  describe Version do

    #-------------------------------------------------------------------------#

    describe "In general" do

      it "raises if initialized with a not valid string representation" do
        should.raise ArgumentError do
          Version.new('v1')
        end.message.should.match /Malformed version string/
      end

      before do
        @sut = Version.new('1.2.0-alpha1.0+20130313144700')
      end

      it "returns the major, minor and patch identifiers" do
        @sut.main_version.should == [1, 2, 0]
      end

      it "returns the pre-release identifiers" do
        @sut.pre_release_version.should == ['alpha1', 0]
      end

      it "returns the build identifiers" do
        @sut.build_metadata.should == [20130313144700]
      end

    end


    #-------------------------------------------------------------------------#

    describe "Class methods" do

      describe "::valid?" do
        it "accepts a normal version number" do
          Version.valid?('1.9.0').should.be.true
          Version.valid?('1.20.145').should.be.true
        end

        it "accepts pre-release versions" do
          Version.valid?('1.0.0-alpha').should.be.true
          Version.valid?('1.0.0-alpha.1').should.be.true
          Version.valid?('1.0.0-0.3.7').should.be.true
          Version.valid?('1.0.0-x.7.z.92').should.be.true
          Version.valid?('1.0.0-rc1').should.be.true
        end

        it "accepts versions including build metadata" do
          Version.valid?('1.0.0-alpha+001').should.be.true
          Version.valid?('1.0.0+20130313144700').should.be.true
          Version.valid?('1.0.0-beta+exp.sha.5114f85').should.be.true
          Version.valid?('1.2.3+0000.build').should.be.true
        end

        it "doesn't' accepts versions including non numerical characters in the main version" do
          Version.valid?('v0.0.1').should.be.false
          Version.valid?('0.0.1alpha').should.be.false
          Version.valid?('0.0 .1').should.be.false
          Version.valid?('0.1+.1').should.be.false
        end

        it "doesn't' accepts versions with a number of main version identifiers different than 3" do
          Version.valid?('1').should.be.false
          Version.valid?('0.1').should.be.false
          Version.valid?('0.1.0.3').should.be.false
          Version.valid?('0.1-alpha').should.be.false
        end
      end

      describe "::lenient_new" do
        it "supports versions with one identifier" do
          Version.lenient_new('1').to_s.should == '1.0.0'
        end

        it "supports versions with two identifiers" do
          Version.lenient_new('1.0').to_s.should == '1.0.0'
        end
      end

    end


    #-------------------------------------------------------------------------#

    describe "Object methods" do

      before do
        @sut = Version.new('1.2.3')
      end

      it "returns the string representation" do
        @sut.to_s.should == '1.2.3'
      end

      it "returns a string suitable for debugging" do
        @sut.inspect.should == '<StdVer::Version 1.2.3>'
      end

      it "returns whether it is equal to another version" do
        Version.new('1.2.3').should == Version.new('1.2.3')
        Version.new('1.2.3').should.not == Version.new('1.2.4')
      end

      describe "eql?" do
        it "is equal to another initialized with an equal string representation" do
          other = Version.new('1.2.3')
          @sut.should.eql(other)
        end

        it "is not equal to another version initialized with a different string representation" do
          other = Version.new('1.2.4')
          @sut.should.not.eql(other)
        end
      end

      it "returns the hash computed as the hash of the string representation" do
        @sut.hash.should == '1.2.3'.hash
        @sut.hash.should == Version.new('1.2.3').hash
      end


      describe "<=>" do
        it "returns nil if compared to an object of another class" do
          (@sut <=> 'String').should.be.nil
        end

        it "always compares Major, minor, and patch versions numerically" do
          v1 = Version.new('1.0.0')
          v2 = Version.new('2.0.0')
          v3 = Version.new('2.1.0')
          v4 = Version.new('2.1.1')
          (v1 < v2).should.be.true
          (v2 < v3).should.be.true
          (v3 < v4).should.be.true
        end

        it "assigns lower precedence to pre-release versions" do
          v1 = Version.new('1.0.0-alpha')
          v2 = Version.new('1.0.0')
          (v1 < v2).should.be.true
        end

        it "handles pre-release fields properly" do
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

    describe "Semantic Versioning" do

      it "identifies release versions" do
        version = Version.new('1.0.0')
        version.should.not.be.pre_release
      end

      it "identifies pre-release versions" do
        version = Version.new('1.0.0-x.7.z.92')
        version.should.be.pre_release
      end

      it "returns the major identifier" do
        Version.new("1.9.0").major.should == 1
        Version.new("1.0.0-alpha").major.should == 1
      end

      it "returns the minor identifier" do
        Version.new("1.9.0").minor.should == 9
        Version.new("1.4.0-alpha").minor.should == 4
      end

      it "returns the patch identifier" do
        Version.new("1.9.4").patch.should == 4
        Version.new("1.0.1-alpha").patch.should == 1
      end

      it "returns the release version" do
        Version.new("1.9.4").release_version.to_s.should == '1.9.4'
        Version.new("1.9.4-rc0").release_version.to_s.should == '1.9.4'
      end

      it "returns the optimistic recommendation" do
        Version.new("1.9.4").optimistic_recommendation.should == '~> 1.9'
        Version.new("0.9.4").optimistic_recommendation.should == '~> 0.9.4'
        Version.new("0.9.4-rc0").optimistic_recommendation.should == '~> 0.9.4'
      end
    end


    #-------------------------------------------------------------------------#

    describe "Next Versions" do

      before do
        @sut = Version.new('1.2.3-rc.1')
      end

      it "returns the next major version" do
        @sut.next_major.to_s.should == '2.0.0'
      end

      it "returns the next minor version" do
        @sut.next_minor.to_s.should == '1.3.0'
      end

      it "returns the next patch version" do
        @sut.next_patch.to_s.should == '1.2.4'
      end

      it "returns the next pre-release version" do
        Version.new("1.2.3-rc.1").next_pre_release.to_s.should == '1.2.3-rc.2'
        Version.new("1.2.3-rc1").next_pre_release.to_s.should == '1.2.3-rc2'
        Version.new("1.2.3-rc1ver").next_pre_release.to_s.should == '1.2.3-rc2ver'
        Version.new("1.2.3-rc1ver2").next_pre_release.to_s.should == '1.2.3-rc2ver2'
        Version.new("1.2.3-rc.1.alpha").next_pre_release.to_s.should == '1.2.3-rc.2'
        Version.new("1.2.3-alpha").next_pre_release.should.be.nil
        Version.new("1.2.3").next_pre_release.should.be.nil
      end

      it "returns the next versions" do
        versions = @sut.next_versions.map(&:to_s)
        versions.should == ["2.0.0", "1.3.0", "1.2.4", "1.2.3-rc.2"]
      end

      it "returns whether a given version would be a valid next version" do
        @sut.valid_next_version?('1.3.0').should.be.true
        @sut.valid_next_version?('1.3.3').should.be.false
      end

    end


    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      before do
        @sut = Version.new('1.2.3')
      end

      describe "#segments_from_string" do
        it "properly converts numeric segments" do
          @sut.send(:segments_from_string, '1.2.3').should == [1, 2, 3]
        end

        it "handles pre-release segments" do
          @sut.send(:segments_from_string, '1.2.3-rc.0').should == [1, 2, 3, 'rc', 0]
        end
      end

      describe "#version_to_string" do
        it "converts the segments of a release version" do
          @sut.send(:version_to_string, [1, 2, 3]).should == '1.2.3'
        end

        it "includes pre-release identifiers" do
          @sut.send(:version_to_string, [1, 2, 3], ['rc', '0']).should == '1.2.3-rc.0'
          @sut.send(:version_to_string, [1, 2, 3], ['alpha']).should == '1.2.3-alpha'
        end

        it "includes build identifiers" do
          @sut.send(:version_to_string, [1, 2, 3], ['rc', '0'], [2012]).should == '1.2.3-rc.0+2012'
          @sut.send(:version_to_string, [1, 2, 3], [], [2012]).should == '1.2.3+2012'
        end
      end

    end


    #-------------------------------------------------------------------------#

  end
end

