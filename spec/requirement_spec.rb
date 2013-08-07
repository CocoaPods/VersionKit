require File.expand_path('../spec_helper', __FILE__)

module StdVer
  describe Requirement do

    #-------------------------------------------------------------------------#

    describe "In general" do

      it "can be initialized with a version" do
        sut = Requirement.new('1.0.0')
        sut.operator.should == '='
        sut.version.should == '1.0.0'
      end

      it "can be initialized with a non normalized version" do
        sut = Requirement.new('1.0')
        sut.operator.should == '='
        sut.version.should == '1.0.0'
      end

      it "can be initialized with a given operator" do
        sut = Requirement.new('!= 2.1.3')
        sut.operator.should == '!='
        sut.version.should == '2.1.3'
      end

      it "raises if initialized with an unsupported operator" do
        should.raise ArgumentError do
          Requirement.new('$ 1.0.0')
        end.message.should.match /Unsupported operator/
      end

      it "raises if initialized with a non valid version" do
        should.raise ArgumentError do
          Requirement.new('!= 2.1-rc0')
        end.message.should.match /Malformed version/
      end

      describe "#satisfied_by?" do
        it "returns whether the `=` is satisfied by another version" do
          sut = Requirement.new('= 2.1.0')
          sut.should.be.satisfied_by?('2.1.0')
          sut.should.be.satisfied_by?('2.1')
          sut.should.be.not.satisfied_by?('2.2.0')
        end

        it "returns whether the `!=` is satisfied by another version" do
          sut = Requirement.new('!= 2.1.0')
          sut.should.be.not.satisfied_by?('2.1.0')
          sut.should.be.not.satisfied_by?('2.1')
          sut.should.be.satisfied_by?('2.2.0')
        end

        it "returns whether the `~>` is satisfied by another version" do
          sut = Requirement.new('~> 2.1.0')
          sut.should.be.satisfied_by?('2.1.0')
          sut.should.be.satisfied_by?('2.1')
          sut.should.be.satisfied_by?('2.1.5')
          sut.should.be.not.satisfied_by?('2.2.0')
          sut.should.be.not.satisfied_by?('2.2')
        end


      end

    end


    #-------------------------------------------------------------------------#

    describe "Class methods" do

    end


    #-------------------------------------------------------------------------#

    describe "Object methods" do

      it "returns the string representation" do
        sut = Requirement.new('!= 2.1.0')
        sut.to_s.should == '!= 2.1.0'
      end

      it "normalized the string representation" do
        sut = Requirement.new('!=   2.1')
        sut.to_s.should == '!= 2.1.0'
      end

    end


    #-------------------------------------------------------------------------#

    describe "Semantic Versioning" do

    end


    #-------------------------------------------------------------------------#

    describe "Next Versions" do

    end


    #-------------------------------------------------------------------------#

    describe "Private helpers" do



    end


    #-------------------------------------------------------------------------#

  end
end

