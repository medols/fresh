require File.expand_path('../spec_helper', __FILE__)

describe "init" do

  it "2 nodes" do
    ( proc{ 2 }*2 ).should == [2,2]
  end

  it "4 nodes" do
    ( proc{ 4 }*4 ).should == [4,4,4,4]
  end

  it "100 nodes" do
    ( proc{ 100 }*100 ).should == [100]*100
  end

end

