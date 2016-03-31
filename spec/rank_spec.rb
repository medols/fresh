require File.expand_path('../spec_helper', __FILE__)

describe "rank" do

  it "2 nodes" do
    ( proc{ rank }*2 ).should == [0,1]
  end

  it "4 nodes" do
    ( proc{ rank }*4 ).should == [0,1,2,3]
  end

  it "NS nodes" do
    ( proc{ rank }*NS ).should == NS.times.to_a
  end

end

