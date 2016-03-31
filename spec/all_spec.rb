require File.expand_path('../spec_helper', __FILE__)

describe "all" do

  it "2 nodes" do
    ( proc{ all }*2 ).should == [[0, 1], [0, 1]]
  end

  it "4 nodes" do
    ( proc{ all }*4 ).should == [[0,1,2,3]]*4
  end

  it "NS nodes" do
    ( proc{ all }*NS ).should == [(0...NS).to_a]*NS 
  end

end

