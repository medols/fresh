require File.expand_path('../spec_helper', __FILE__)

describe "mpi_sendrecv" do

  it "mpi_sendrecv 2" do

    res = proc{ |rank,size| 
            mpi_sendrecv [rank+9] , [0] , [0] , [1] , rank 
          }*2 

    res.size.should == 2
    res.should == [[10],[0]]

  end

  it "mpi_sendrecv 4" do

    res = proc{ |rank,size| 
            mpi_sendrecv [rank+9] , [0] , [0,2] , [1,3] , rank 
          }*4 

    res.size.should == 4
    res.should == [[10],[0],[12],[0]]

  end

  it "mpi_sendrecv 100" do

    res = proc{ |rank,size| 
            mpi_sendrecv [rank+9] , [0] , (0..98).step(2) , (1..99).step(2) , rank 
          }*100 

    res.size.should == 100
    res.should == 100.times.map{|i| (i.even?)?[i+9+1]:[0] }

  end

end

