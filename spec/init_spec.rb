require File.expand_path('../spec_helper', __FILE__)

describe "init" do

  it "2 nodes" do
    ( proc{ 2 }*2 ).should == [2,2]
  end

  it "4 nodes" do
    ( proc{ 4 }*4 ).should == [4,4,4,4]
  end

  it "NS nodes" do
    ( proc{ NS }*NS ).should == [NS]*NS
  end

end

