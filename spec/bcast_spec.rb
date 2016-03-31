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

  it "4 nodes with default from: and to:" do

    res = proc{ bcast size-rank }*4
    res.size.should == 4
    res.should == [[4], [4], [4], [4]]

  end

  it "4 nodes with default to:" do

    res = proc{ bcast size-rank , from:1 }*4
    res.size.should == 4
    res.should == [[3], [3], [3], [3]]

  end

  it "4 nodes with default from:" do

    res = proc{ bcast size-rank , to:[1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [4], [4], [4]]

  end

  it "4 nodes without defaults" do

    res = proc{ bcast size-rank , from:1 , to:[1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [3], [3], [3]]

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

  it "NS nodes" do

    res = proc{
            bcast [128] , [0] , 0 , 1...NS
          }*NS

    res.size.should == NS
    res.first.should == [0]
    res[1..-1].should == [ [128] ] * (NS-1)

  end

  it "NS nodes with tx/rx intersection" do

    res = proc{
            bcast [128] , [0] , 0 , NS.times 
          }*NS

    res.should == [ [128] ] * NS

  end

  it "4 nodes array method" do

    res = proc{ [32].bcast [0] , 0 , [1,2,3] }*4
    res.should == [ [0] , [32] , [32] , [32] ]

  end

  it "4 nodes array method with tx/rx intersection" do

    res = proc{
            [32].bcast [0] , 0 , [0,1,2,3] 
          }*4

    res.should == [ [32] , [32] , [32] , [32] ]

  end

  it "4 nodes array method with default from: and to:" do

    res = proc{ [size-rank].bcast }*4
    res.size.should == 4
    res.should == [[4], [4], [4], [4]]

  end

  it "4 nodes array method with default to:" do

    res = proc{ [size-rank].bcast from:1 }*4
    res.size.should == 4
    res.should == [[3], [3], [3], [3]]

  end

  it "4 nodes array method with default from:" do

    res = proc{ [size-rank].bcast to:[1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [4], [4], [4]]

  end

  it "4 nodes array method without defaults" do

    res = proc{ [size-rank].bcast from:1 , to:[1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [3], [3], [3]]

  end

  it "8 nodes array method" do

    res = proc{
            [64].bcast [0] , 0 , [1,2,3,4,5,6,7] 
          }*8

    res.size.should == 8
    res.first.should == [0]
    res[1..-1].should == [ [64] ] * 7

  end

  it "8 nodes array method with tx/rx intersection" do

    res = proc{
            [64].bcast [0] , 0 , [0,1,2,3,4,5,6,7] 
          }*8

    res.should == [ [64] ] * 8

  end

  it "NS nodes array method" do

    res = proc{
            [128].bcast [0] , 0 , 1...NS
          }*NS

    res.size.should == NS
    res.first.should == [0]
    res[1..-1].should == [ [128] ] * (NS-1)

  end

  it "NS nodes array method with tx/rx intersection" do

    res = proc{
            [128].bcast [0] , 0 , NS.times 
          }*NS

    res.should == [ [128] ] * NS

  end

end
