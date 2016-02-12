require File.expand_path('../spec_helper', __FILE__)

describe "size" do

  it "2 nodes" do
    ( proc{ size }*2 ).should == [2,2]
  end

  it "4 nodes" do
    ( proc{ size }*4 ).should == [4,4,4,4]
  end

  it "100 nodes" do
    ( proc{ size }*100 ).should == [100]*100
  end

end

