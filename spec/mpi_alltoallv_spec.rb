describe "mpi_scatterv" do

  it "mpi_alltoallv 4" do

    res = proc{ |rank,size|
            mpi_alltoallv [3,2] , [0,0] , [0,1] , [2,3] , rank
          }*4

    res.size.should == 4
    res.should == [[0,0], [0,0], [3,3], [2,2]]

  end

  it "mpi_alltoall 8" do

    res = proc{ |rank,size|
            mpi_alltoallv [7,6,5,4], [0,0,0,0] , [0,1,2,3] , [4,5,6,7] , rank
          }*8

    res.size.should == 8
    res[0..3].should == [[0]*4]*4
    res[4..7].should == [[7]*4, [6]*4, [5]*4, [4]*4]

  end

#  it "mpi_alltoall 100" do
#
#    res = proc{ |rank,size|
#            mpi_alltoallv (1..99).to_a.reverse, [0] , 0 , (1..99) , rank
#          }*100
#
#    res.size.should == 100 
#    res.first.should == [0] 
#    res[1..-1].should == (1..99).to_a.reverse.map{|i|[i]}
#
#  end

end
