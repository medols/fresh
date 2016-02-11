require File.expand_path('../spec_helper', __FILE__)

describe "Broadcast with bcast" do

  it "4 nodes" do

    res = proc{ bcast [32] , [0] , 0 , [1,2,3] }*4
    res.should == [ [0] , [32] , [32] , [32] ]

  end

  it "4 nodes with tx/rx intersection" do

    res = proc{
            bcast [32] , [0] , 0 , [0,1,2,3] 
          }*4

    res.should == [ [32] , [32] , [32] , [32] ]

  end

  it "8 nodes" do

    res = proc{
            bcast [64] , [0] , 0 , [1,2,3,4,5,6,7] 
          }*8

    res.size.should == 8
    res.first.should == [0]
    res[1..-1].should == [ [64] ] * 7

  end

  it "8 nodes with tx/rx intersection" do

    res = proc{
            bcast [64] , [0] , 0 , [0,1,2,3,4,5,6,7] 
          }*8

    res.should == [ [64] ] * 8

  end

  it "100 nodes" do

    res = proc{
            bcast [128] , [0] , 0 , 1..99 
          }*100

    res.size.should == 100 
    res.first.should == [0]
    res[1..-1].should == [ [128] ] * 99

  end

  it "100 nodes with tx/rx intersection" do

    res = proc{
            bcast [128] , [0] , 0 , 100.times 
          }*100

    res.should == [ [128] ] * 100

  end

end
