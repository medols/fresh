describe "mpi_allgatherv" do

  it "allgatherv 5" do

    res = proc{ |rank,size|
            val=[[], [], [], [ 4, 2, 3, 8, 4, 6, 1], [ 2, 4, 8,16,32,64,48]]
            7.times.map{|i|
              mpi_allgatherv [val[rank][i]] , [0,0] , [3,4] , [0,1,2] , rank
            }
          }*5

    res[0].should == [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]]
    res[1].should == [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]]
    res[2].should == [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]]
    res[3].should == [[0, 0], [0, 0], [0, 0], [0,  0], [0,  0], [0,  0], [0,  0]]
    res[4].should == [[0, 0], [0, 0], [0, 0], [0,  0], [0,  0], [0,  0], [0,  0]]

  end

#  it "mpi_gatherv 8" do
#
#    res = proc{ |rank,size|
#            mpi_gatherv [rank+9] , [0,0,0,0,0,0,0] , 0 , [1,2,3,4,5,6,7] , rank
#          }*8
#
#    res.first.should == (10..16).to_a
#    res[1..-1].should == [ [0]*7 ]*7
#
#  end

#  it "mpi_gatherv 100" do
#
#    res = proc{ |rank,size|
#            mpi_gatherv [rank+9] , [0]*99 , 0 , (1..99).to_a , rank
#          }*100
#
#    res.first.should == (10..108).to_a
#    res[1..-1].should == [ [0]*99 ]*99
#
#  end

end
