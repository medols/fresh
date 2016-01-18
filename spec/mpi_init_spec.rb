require File.expand_path('../spec_helper', __FILE__)

describe "mpi_init" do

  it "mpi_init 2" do
    ( proc{ 2 }*2 ).should == [2,2]
  end

  it "mpi_init 4" do
    ( proc{ 4 }*4 ).should == [4,4,4,4]
  end

  it "mpi_init 100" do
    ( proc{ 100 }*100 ).should == [100]*100
  end

end

