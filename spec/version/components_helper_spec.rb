require File.expand_path('../../spec_helper', __FILE__)

module VersionKit
  describe Version::ComponentsHelper do
    before do
      @subject = Version::ComponentsHelper
    end

    describe '::split_components' do
      it 'splits the components and the dash and plus characters' do
        version = '1.2.3-rc.1+2014.01.01'
        result = @subject.split_components(version)
        result.count.should == 3
      end

      it 'splits each component in identifiers' do
        version = '1.2.3-rc.1+2014.01.01'
        result = @subject.split_components(version)
        result.should == [[1, 2, 3], ['rc', 1], [2014, 1, 1]]
      end

      it 'returns the empty array for missing components' do
        version = '1.2.3'
        result = @subject.split_components(version)
        result.count.should == 3
      end

      it 'caps the components to a maximum of 3' do
        version = '1.2.3-rc.1+2014.01.01+1.2.3-rc.1+2014.01.01'
        result = @subject.split_components(version)
        result.count.should == 3
      end
    end

    describe '::split_identifiers' do
      it 'splits the identifiers at the dot' do
        component = 'id1.id2.rc'
        @subject.split_identifiers(component).should == %w(id1 id2 rc)
      end

      it 'converts strings composed only by digits to an integer' do
        component = '1.rc.2'
        result = @subject.split_identifiers(component)
        result.should == [1, 'rc', 2]
      end
    end

    describe '::compare_number_component' do
      it 'compares the identifiers numerically from left to right' do
        first = [1, 4, 1]
        second = [1, 4, 7]
        @subject.compare_number_component(first, second).should == -1
        @subject.compare_number_component(second, first).should == +1
      end

      it 'returns zero if the components have the same precedence' do
        first = [1, 4, 1]
        @subject.compare_number_component(first, first).should.be.nil
        @subject.compare_number_component(first, first).should.be.nil
      end
    end

    describe '::compare_pre_release_component' do
      it 'compares the identifiers from left to right' do
        first = [1, 4, 1]
        second = [1, 4, 7]
        @subject.compare_pre_release_component(first, second).should == -1
        @subject.compare_pre_release_component(second, first).should == +1
      end

      it 'compares digits identifiers numerically' do
        first = [1, 4, 2]
        second = [1, 4, 15]
        @subject.compare_pre_release_component(first, second).should == -1
        @subject.compare_pre_release_component(second, first).should == +1
      end

      it 'compares string identifiers in ASCII sort order' do
        first = [1, 4, 'rc-2']
        second = [1, 4, 'rc-15']
        @subject.compare_pre_release_component(first, second).should == +1
        @subject.compare_pre_release_component(second, first).should == -1
      end

      it 'assigns lower precedence to numeric identifiers' do
        first = [1, 4, 1]
        second = [1, 4, 'rc-25']
        @subject.compare_pre_release_component(first, second).should == -1
        @subject.compare_pre_release_component(second, first).should == +1
      end

      it 'assigns higher precedence to larger sets' do
        first = [1, 4, 2]
        second = [1, 4, 2, 1]
        @subject.compare_pre_release_component(first, second).should == -1
        @subject.compare_pre_release_component(second, first).should == +1
      end

      it 'returns zero if the components have the same precedence' do
        first = ['rc', 1, 'gamma1']
        @subject.compare_pre_release_component(first, first).should.be.nil
        @subject.compare_pre_release_component(first, first).should.be.nil
      end
    end

    describe '::compare_pre_release_identifiers' do
      it 'assigns lower precedence to nil values' do
        first = nil
        second = 1
        @subject.compare_pre_release_identifiers(first, second).should == -1
        @subject.compare_pre_release_identifiers(second, first).should == +1
      end

      it 'assigns higher precedence to string values' do
        first = 1
        second = '1'
        @subject.compare_pre_release_identifiers(first, second).should == -1
        @subject.compare_pre_release_identifiers(second, first).should == +1
      end

      it 'compares digit identifiers numerically' do
        first = 2
        second = 12
        @subject.compare_pre_release_identifiers(first, second).should == -1
        @subject.compare_pre_release_identifiers(second, first).should == +1
      end

      it 'compares string identifiers numerically' do
        first = 'rc12'
        second = 'rc2'
        @subject.compare_pre_release_identifiers(first, second).should == -1
        @subject.compare_pre_release_identifiers(second, first).should == +1
      end
    end

    describe '::compare' do
      it 'returns whether only one of the values is truthy' do
        @subject.compare(true, false).should == +1
        @subject.compare(false, true).should == -1
      end

      it 'returns nil if there is no only one truthy value' do
        @subject.compare(true, true).should.be.nil
        @subject.compare(false, false).should.be.nil
      end

      it 'handles nil as parameter' do
        @subject.compare('value', nil).should == +1
        @subject.compare(nil, 'value').should == -1
        @subject.compare(nil, nil).should.be.nil
        @subject.compare('value', 'another_value').should.be.nil
      end
    end

    describe '::compare' do
      it 'rejects objects which are not an array' do
        @subject.validate_components?('components').should.be.false
      end

      it 'rejects arrays which do not contain only arrays' do
        @subject.validate_components?(['components']).should.be.false
      end

      it 'rejects arrays with a number of components different than 3' do
        @subject.validate_components?([[]]).should.be.false
      end

      it 'rejects number components with a incorrect number of identifiers' do
        @subject.validate_components?([[1]]).should.be.false
      end

      it 'rejects string identifiers for number components' do
        components = [[1, 2, '3'], [], []]
        @subject.validate_components?(components).should.be.false
      end

      it 'checks the class of the pre-release identifiers' do
        components = [[1, 2, 3], [nil], []]
        @subject.validate_components?(components).should.be.false
      end

      it 'checks the class of the build identifiers' do
        components = [[1, 2, 3], [], [nil]]
        @subject.validate_components?(components).should.be.false
      end

      it 'accepts valid components' do
        components = [[1, 2, 0], ['alpha1', 0], [20_130_313_144_700]]
        @subject.validate_components?(components).should.be.true
      end
    end
  end
end
