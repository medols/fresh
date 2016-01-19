describe "mpi_bcastv" do

  it "mpi_bcastv 4" do

    res = proc{ |rank,size|
            mpi_bcastv [32] , [0] , 0 , [1,2,3] , rank
          }*4

    res.should == [ [0] , [32] , [32] , [32] ]

  end

  it "mpi_bcastv 8" do

    res = proc{ |rank,size|
            mpi_bcastv [64] , [0] , 0 , [1,2,3,4,5,6,7] , rank
          }*8

    res.first.should == [0]
    res[1..-1].should == [ [64] ] * 7

  end

  it "mpi_bcastv 100" do

    res = proc{ |rank,size|
            mpi_bcastv [128] , [0] , 0 , (1...100).to_a , rank
          }*100

    res.first.should == [0]
    res[1..-1].should == [ [128] ] * 99

  end

end
