require File.expand_path('../spec_helper', __FILE__)

describe "scatter" do

  it "4 nodes" do

    res = proc{ scatter [3,2,1] , [0] , 0 , [1,2,3]}*4
    res.size.should == 4
    res.should == [[0], [3], [2], [1]]

  end

  it "4 nodes with tx/rx intersection" do

    res = proc{ scatter [3,2,1,0] , [0] , 0 , [0,1,2,3]}*4
    res.size.should == 4
    res.should == [[3], [2], [1], [0]]

  end

  it "4 nodes with default from: and to:" do

    res = proc{ scatter all.reverse }*4
    res.size.should == 4
    res.should == [[3], [2], [1], [0]]

  end

  it "4 nodes with default to:" do

    res = proc{ scatter [rank]*4 , from:1 }*4
    res.size.should == 4
    res.should == [[1], [1], [1], [1]]

  end

  it "4 nodes with default from:" do

    res = proc{ scatter [2,1,0] , to:[1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [2], [1], [0]]

  end

  it "4 nodes without defaults" do

    res = proc{ scatter [rank]*3 , from:1 , to:[1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [1], [1], [1]]

  end

  it "8 nodes" do

    res = proc{
            scatter [7,6,5,4,3,2,1], [0] , 0 , [1,2,3,4,5,6,7] 
          }*8

    res.size.should == 8
    res.first.should == [0] 
    res[1..-1].should == [ [7], [6], [5], [4], [3], [2], [1]]

  end

  it "8 nodes with tx/rx intersection" do

    res = proc{
            scatter [7,6,5,4,3,2,1,0], [0] , 0 , [0,1,2,3,4,5,6,7] 
          }*8

    res.size.should == 8
    res.should == [ [7], [6], [5], [4], [3], [2], [1], [0]]

  end


  it "NS nodes" do

    res = proc{
            scatter [*(1...NS)].reverse, [0] , 0 , (1...NS)
          }*NS

    res.size.should == NS
    res.first.should == [0] 
    res[1..-1].should == (1...NS).to_a.reverse.map{|i|[i]}

  end

  it "NS nodes with tx/rx intersection" do

    res = proc{
            scatter [*(0...NS)].reverse, [0] , 0 , (0...NS)
          }*NS

    res.size.should == NS 
    res.should == (0...NS).to_a.reverse.map{|i|[i]}

  end

  it "4 nodes array method" do

    res = proc{ [3,2,1].scatter [0] , 0 , [1,2,3]}*4
    res.size.should == 4
    res.should == [[0], [3], [2], [1]]

  end

  it "4 nodes array method with tx/rx intersection" do

    res = proc{ [3,2,1,0].scatter  [0] , 0 , [0,1,2,3]}*4
    res.size.should == 4
    res.should == [[3], [2], [1], [0]]

  end

  it "4 nodes array method with default from: and to:" do

    res = proc{ all.reverse.scatter }*4
    res.size.should == 4
    res.should == [[3], [2], [1], [0]]

  end

  it "4 nodes array method with default to:" do

    res = proc{ ([rank]*4).scatter from:1 }*4
    res.size.should == 4
    res.should == [[1], [1], [1], [1]]

  end

  it "4 nodes array method with default from:" do

    res = proc{ [2,1,0].scatter to:[1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [2], [1], [0]]

  end

  it "4 nodes array method without defaults" do

    res = proc{ ([rank]*3).scatter from:1 , to:[1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [1], [1], [1]]

  end

  it "8 nodes array method" do

    res = proc{
            [7,6,5,4,3,2,1].scatter [0] , 0 , [1,2,3,4,5,6,7] 
          }*8

    res.size.should == 8
    res.first.should == [0] 
    res[1..-1].should == [ [7], [6], [5], [4], [3], [2], [1]]

  end

  it "8 nodes array method with tx/rx intersection" do

    res = proc{
            all.reverse.scatter [0] , 0 , [0,1,2,3,4,5,6,7] 
          }*8

    res.size.should == 8
    res.should == [ [7], [6], [5], [4], [3], [2], [1], [0]]

  end


  it "NS nodes array method" do

    res = proc{
            [*(1...NS)].reverse.scatter [0] , 0 , (1...NS)
          }*NS

    res.size.should == NS
    res.first.should == [0] 
    res[1..-1].should == (1...NS).to_a.reverse.map{|i|[i]}

  end

  it "NS nodes array method with tx/rx intersection" do

    res = proc{
            [*(0...NS)].reverse.scatter [0] , 0 , (0...NS)
          }*NS

    res.size.should == NS
    res.should == (0...NS).to_a.reverse.map{|i|[i]}

  end


end
