describe "mpi_scatterv" do

  it "mpi_scatterv 4" do

    res = proc{ |rank,size|
            mpi_scatterv [3,2,1] , [0] , 0 , [1,2,3] , rank
          }*4

    res.should == [[0], [3], [2], [1]]

  end

  it "mpi_scatterv 8" do

    res = proc{ |rank,size|
            mpi_scatterv [7,6,5,4,3,2,1], [0] , 0 , [1,2,3,4,5,6,7] , rank
          }*8

    res.first.should == [0] 
    res[1..-1].should == [ [7], [6], [5], [4], [3], [2], [1]]

  end

  it "mpi_scatterv 100" do

    res = proc{ |rank,size|
            mpi_scatterv (1..99).to_a.reverse, [0] , 0 , (1..99) , rank
          }*100

    res.first.should == [0] 
    res[1..-1].should == (1..99).to_a.reverse.map{|i|[i]}

  end

end
