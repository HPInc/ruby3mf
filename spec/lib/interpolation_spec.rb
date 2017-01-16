require 'spec_helper'

describe "Interpolation" do

    include Interpolation

    describe "with no interpolation parameter" do
      it "should not change the string" do
        expect(interpolate("Hi %{name}!")).to eq("Hi !")
      end

      it "should not change the string and not have variable to interpolate" do
        expect(interpolate("Hi !")).to eq("Hi !")
      end

    end

    describe "with interpolation parameter" do
      it "should change the string with one parameter" do
        expect(interpolate("Hi %{name}!", {:name => "Foo"})).to eq("Hi Foo!")
      end

      it "should change the string with one parameter when use %% as interpolation" do
        expect(interpolate('%{bar} %%{foo}', :bar => 'Barr')).to eq('Barr %{foo}')
      end

      it "should change the string with more than one parameters" do
        expect(interpolate("Hi %{name}, from %{country}", {:name => "Marlon", :country => "Brazil"})).to eq("Hi Marlon, from Brazil")
      end

      it "should accept a lambda as a parameter for interpolation" do
        expect(interpolate('Hi %{name}!', :name => lambda { |*args| 'David' })).to eq('Hi David!')
      end
    end

    describe "when symbolize hash ley is needed" do
      it "should change string keys for symbols keys" do
        expect(symbolize_recursive({"a" => [{"b" => "c"}]})).to eq({:a => [{:b => "c"}]})
      end
    end


end
