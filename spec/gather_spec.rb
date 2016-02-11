require File.expand_path('../spec_helper', __FILE__)

describe "gather" do

  it "4 nodes" do

    res = proc{ gather [rank+9] , [0,0,0] , 0 , [1,2,3] }*4
    res.size.should == 4
    res.should == [[10,11,12], [0,0,0], [0,0,0], [0,0,0]]

  end

  it "4 nodes with tx/rx intersection" do

    res = proc{
            gather [rank+9] , [0,0,0,0] , 0 , [0,1,2,3]
          }*4

    res.size.should == 4
    res.should == [[9,10,11,12], [0,0,0,0], [0,0,0,0], [0,0,0,0]]

  end

  it "8 nodes" do

    res = proc{
            gather [rank+9] , [0,0,0,0,0,0,0] , 0 , [1,2,3,4,5,6,7]
          }*8

    res.size.should == 8
    res.first.should == (10..16).to_a
    res[1..-1].should == [ [0]*7 ]*7

  end

  it "8 nodes with tx/rx intersection" do

    res = proc{
            gather [rank+9] , [0,0,0,0,0,0,0,0] , 0 , [0,1,2,3,4,5,6,7]
          }*8

    res.size.should == 8
    res.first.should == (9..16).to_a
    res[1..-1].should == [ [0]*8 ]*7

  end

  it "100 nodes" do

    dim = 100
    res = proc{
            gather [rank+9] , [0]*(dim-1) , 0 , 1..(dim-1) 
          }*dim

    res.size.should == dim
    res.first.should == (10..(dim+8)).to_a
    res[1..-1].should == [ [0]*(dim-1) ]*(dim-1)

  end

  it "100 nodes with tx/rx intersection" do

    dim = 100
    res = proc{
            gather [rank+9] , [0]*dim , 0 , 0..(dim-1)
          }*dim

    res.size.should == dim
    res.first.should == (9..(dim+8)).to_a
    res[1..-1].should == [ [0]*dim ]*(dim-1)

  end

end
