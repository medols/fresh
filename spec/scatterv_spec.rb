require File.expand_path('../spec_helper', __FILE__)

describe "scatterv" do

  it "4 nodes" do
    res = proc{ scatterv [2,2,2,1] , [0,1,2,3] , [3,2,1,0] , [0] , 0 , [0,1,2,3]}*4
    res.size.should == 4
    res.should == [[3, 2], [2, 1], [1, 0], [0]]
  end

  it "4 nodes array method" do
    res = proc{ [3,2,1,0].scatterv [2,2,2,1] , [0,1,2,2] , [0] , 0 , [0,1,2,3]}*4
    res.size.should == 4
    res.should == [[3, 2], [2, 1], [1, 0], [1]]
  end

  it "4 nodes array method with defaults" do
    res = proc{ [3,2,1,0].scatterv [2,2,2,1] , [0,1,2,2] }*4
    res.size.should == 4
    res.should == [[3, 2], [2, 1], [1, 0], [1]]
  end

end
