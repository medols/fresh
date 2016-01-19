require File.expand_path('../spec_helper', __FILE__)

describe "mpi_sendrecv" do

  it "mpi_sendrecv 2" do
    ( proc{ |rank,size| mpi_sendrecv [rank+9] , [0] , [0] , [1] , rank }*2 ).should == [[10],[0]]
  end

  it "mpi_sendrecv 4" do
    ( proc{ |rank,size| 
      mpi_sendrecv [rank+9] , [0] , [0,2] , [1,3] , rank 
    }*4 ).should == [[10],[0],[12],[0]]
  end

  it "mpi_sendrecv 100" do
    ( proc{ |rank,size| 
      rcv=50.times.map{|i| 2*i}
      snd=50.times.map{|i| 2*i+1}
      mpi_sendrecv [rank+9] , [0] , rcv , snd , rank 
    }*100 ).should == 100.times.map{|i| (i.even?)?[i+10]:[0] }
  end

end

