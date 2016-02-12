require File.expand_path('../spec_helper', __FILE__)

describe "alltoall" do

  it "4 nodes" do

    res = proc{ alltoall [3,2] , [0,0] , [0,1] , [2,3] }*4
    res.size.should == 4
    res.should == [[0,0], [0,0], [3,3], [2,2]]

  end

  it "8 nodes" do

    res = proc{
            alltoall [7,6,5,4], [0,0,0,0] , [0,1,2,3] , [4,5,6,7] 
          }*8

    res.size.should == 8
    res[0..3].should == [[0]*4]*4
    res[4..7].should == [[7]*4, [6]*4, [5]*4, [4]*4]

  end

  it "100 nodes" do

    res = proc{
            alltoall (50..99).to_a.reverse, [0]*50 , 0..49 , 50..99
          }*100

    res.size.should == 100 
    res[0..49].should == [[0]*50]*50
    res[50..-1].should == (50..99).to_a.reverse.map{|i|[i]*50}

  end

end
