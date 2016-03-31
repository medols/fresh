require File.expand_path('../spec_helper', __FILE__)

describe "alltoall" do

  it "4 nodes" do

    res = proc{ alltoall [3,2] , [0,0] , [2,3] , [0,1] }*4
    res.size.should == 4
    res.should == [[0,0], [0,0], [3,3], [2,2]]

  end

  it "4 nodes without defaults" do

    res = proc{ alltoall [3,2] , from:[0,1] , to:[2,3] }*4
    res.size.should == 4
    res.should == [[0,0], [0,0], [3,3], [2,2]]

  end

  it "8 nodes" do

    res = proc{
            alltoall [7,6,5,4], [0,0,0,0] , [4,5,6,7] , [0,1,2,3]
          }*8

    res.size.should == 8
    res[0..3].should == [[0]*4]*4
    res[4..7].should == [[7]*4, [6]*4, [5]*4, [4]*4]

  end

  it "NS nodes" do

    res = proc{
            alltoall ((NS/2)...NS).to_a.reverse, [0]*(NS/2) , (NS/2)...NS , 0...(NS/2)
          }*NS

    res.size.should == NS
    res[0...(NS/2)].should == [[0]*(NS/2)]*(NS/2)
    res[(NS/2)..-1].should == ((NS/2)...NS).to_a.reverse.map{|i|[i]*(NS/2)}

  end

  it "4 nodes array methods" do

    res = proc{  [3,2].alltoall [0,0] , [2,3] , [0,1] }*4
    res.size.should == 4
    res.should == [[0,0], [0,0], [3,3], [2,2]]

  end

  it "4 nodes without defaults" do

    res = proc{ [3,2].alltoall from:[0,1] , to:[2,3] }*4
    res.size.should == 4
    res.should == [[0,0], [0,0], [3,3], [2,2]]

  end

  it "8 nodes" do

    res = proc{
            [7,6,5,4].alltoall [0,0,0,0] , [4,5,6,7] , [0,1,2,3]
          }*8

    res.size.should == 8
    res[0..3].should == [[0]*4]*4
    res[4..7].should == [[7]*4, [6]*4, [5]*4, [4]*4]

  end

  it "NS nodes" do

    res = proc{
            ((NS/2)...NS).to_a.reverse.alltoall [0]*(NS/2) , (NS/2)...NS , 0...(NS/2)
          }*NS

    res.size.should == NS
    res[0...(NS/2)].should == [[0]*(NS/2)]*(NS/2)
    res[(NS/2)..-1].should == ((NS/2)...NS).to_a.reverse.map{|i|[i]*(NS/2)}

  end

end
