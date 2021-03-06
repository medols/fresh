require File.expand_path('../spec_helper', __FILE__)

describe "sendrecv" do

  it "2 nodes" do

    res = proc{ sendrecv [rank+9] , [0] , [0] , [1] }*2 
    res.size.should == 2
    res.should == [[10],[0]]

  end

  it "2 nodes with default to:" do

    res = proc{ sendrecv [rank+9] , from:1 }*2 
    res.size.should == 2
    res.should == [[10],[0]]

  end

  it "2 nodes with default from:" do

    res = proc{ sendrecv [rank+9] , to:1 }*2 
    res.size.should == 2
    res.should == [[0],[9]]

  end

  it "2 nodes without defaults" do

    res = proc{ sendrecv [rank+9] , from:1 , to:root }*2 
    res.size.should == 2
    res.should == [[10],[0]]

  end

#  it "2 nodes with tx/rx intersection" do
#
#    res = proc{ sendrecv [rank+9] , [0] , [0,1] , [1,0] }*2 
#    res.size.should == 2
#    res.should == [[10],[9]]
#
#  end

  it "4 nodes" do

    res = proc{ 
            sendrecv [rank+9] , [0] , [0,2] , [1,3]  
          }*4 

    res.size.should == 4
    res.should == [[10],[0],[12],[0]]

  end

  it "NS nodes" do

    res = proc{ 
            sendrecv [rank+9] , [0] , (0..(NS-2)).step(2) , (1..(NS-1)).step(2)  
          }*NS 

    res.size.should == NS
    res.should == NS.times.map{|i| (i.even?)?[i+10]:[0] }

  end

end

