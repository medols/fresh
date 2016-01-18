require File.expand_path('../spec_helper', __FILE__)

describe "mpi_rank" do

  it "mpi_rank 2" do
    ( proc{ |rank,size| rank }*2 ).should == [0,1]
  end

  it "mpi_rank 4" do
    ( proc{ |rank,size| rank }*4 ).should == [0,1,2,3]
  end

  it "mpi_rank 100" do
    ( proc{ |rank,size| rank }*100 ).should == 100.times.to_a
  end

end

