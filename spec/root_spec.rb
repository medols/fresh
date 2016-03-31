require File.expand_path('../spec_helper', __FILE__)

describe "root" do

  it "2 nodes" do
    ( proc{ root }*2 ).should == [0,0]
  end

  it "4 nodes" do
    ( proc{ root }*4 ).should == [0]*4
  end

  it "NS nodes" do
    ( proc{ root }*NS ).should == [0]*NS
  end

end

