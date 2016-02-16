require File.expand_path('../spec_helper', __FILE__)

describe "sendrecv" do

  it "2 nodes" do

    res = proc{ sendrecv [rank+9] , [0] , [0] , [1] }*2 
    res.size.should == 2
    res.should == [[10],[0]]

  end

  it "4 nodes" do

    res = proc{ 
            sendrecv [rank+9] , [0] , [0,2] , [1,3]  
          }*4 

    res.size.should == 4
    res.should == [[10],[0],[12],[0]]

  end

  it "100 nodes" do

    res = proc{ 
            sendrecv [rank+9] , [0] , (0..98).step(2) , (1..99).step(2)  
          }*100 

    res.size.should == 100
    res.should == 100.times.map{|i| (i.even?)?[i+10]:[0] }

  end

end

