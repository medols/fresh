require File.expand_path('../spec_helper', __FILE__)

describe "mpi_size" do

  it "mpi_size 2" do
    ( proc{ |rank,size| size }*2 ).should == [2,2]
  end

  it "mpi_size 4" do
    ( proc{ |rank,size| size }*4 ).should == [4,4,4,4]
  end

  it "mpi_size 100" do
    ( proc{ |rank,size| size }*100 ).should == [100]*100
  end

end

