describe "mpi_gatherv" do

  it "mpi_gatherv 4" do

    res = proc{ |rank,size|
            mpi_gatherv [rank+9] , [0,0,0] , 0 , [1,2,3] , rank
          }*4

    res.size.should == 4
    res.should == [[10,11,12], [0,0,0], [0,0,0], [0,0,0]]

  end

  it "mpi_gatherv 4 with tx/rx intersection" do

    res = proc{ |rank,size|
            mpi_gatherv [rank+9] , [0,0,0,0] , 0 , [0,1,2,3] , rank
          }*4

    res.size.should == 4
    res.should == [[9,10,11,12], [0,0,0,0], [0,0,0,0], [0,0,0,0]]

  end

  it "mpi_gatherv 8" do

    res = proc{ |rank,size|
            mpi_gatherv [rank+9] , [0,0,0,0,0,0,0] , 0 , [1,2,3,4,5,6,7] , rank
          }*8

    res.size.should == 8
    res.first.should == (10..16).to_a
    res[1..-1].should == [ [0]*7 ]*7

  end

  it "mpi_gatherv 8 with tx/rx intersection" do

    res = proc{ |rank,size|
            mpi_gatherv [rank+9] , [0,0,0,0,0,0,0,0] , 0 , [0,1,2,3,4,5,6,7] , rank
          }*8

    res.size.should == 8
    res.first.should == (9..16).to_a
    res[1..-1].should == [ [0]*8 ]*7

  end

  it "mpi_gatherv 100" do

    res = proc{ |rank,size|
            mpi_gatherv [rank+9] , [0]*99 , 0 , 1..99 , rank
          }*100

    res.size.should == 100
    res.first.should == (10..108).to_a
    res[1..-1].should == [ [0]*99 ]*99

  end

  it "mpi_gatherv 100 with tx/rx intersection" do

    res = proc{ |rank,size|
            mpi_gatherv [rank+9] , [0]*100 , 0 , 0..99 , rank
          }*100

    res.size.should == 100
    res.first.should == (9..108).to_a
    res[1..-1].should == [ [0]*100 ]*99

  end

end
