require File.expand_path('../spec_helper', __FILE__)

describe "scatterv" do

  it "4 nodes" do
    res = proc{ scatterv [3,2,1,0] , [2,2,2,1] , [0,1,2,3] , [0] , 0 , [0,1,2,3]}*4
    res.size.should == 4
    res.should == [[3, 2], [2, 1], [1, 0], [0]]
  end

end
