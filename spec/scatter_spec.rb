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


  it "100 nodes" do

    res = proc{
            scatter [*(1..99)].reverse, [0] , 0 , (1..99)
          }*100

    res.size.should == 100 
    res.first.should == [0] 
    res[1..-1].should == (1..99).to_a.reverse.map{|i|[i]}

  end

  it "100 nodes with tx/rx intersection" do

    res = proc{
            scatter [*(0..99)].reverse, [0] , 0 , (0..99)
          }*100

    res.size.should == 100 
    res.should == (0..99).to_a.reverse.map{|i|[i]}

  end

end
