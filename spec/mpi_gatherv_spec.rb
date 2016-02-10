describe "mpi_gatherv" do

  it "mpi_gatherv 4" do

    res = proc{
            mpi_gatherv [rank+9] , [0,0,0] , 0 , [1,2,3] , rank
          }*4

    res.size.should == 4
    res.should == [[10,11,12], [0,0,0], [0,0,0], [0,0,0]]

  end

  it "mpi_gatherv 4 2" do

    res = proc{ gather [rank+9] , [0,0,0] , 0 , [1,2,3] }*4
    res.size.should == 4
    res.should == [[10,11,12], [0,0,0], [0,0,0], [0,0,0]]

  end

  it "mpi_gatherv 4 with tx/rx intersection" do

    res = proc{
            mpi_gatherv [rank+9] , [0,0,0,0] , 0 , [0,1,2,3] , rank
          }*4

    res.size.should == 4
    res.should == [[9,10,11,12], [0,0,0,0], [0,0,0,0], [0,0,0,0]]

  end

  it "mpi_gatherv 8" do

    res = proc{
            mpi_gatherv [rank+9] , [0,0,0,0,0,0,0] , 0 , [1,2,3,4,5,6,7] , rank
          }*8

    res.size.should == 8
    res.first.should == (10..16).to_a
    res[1..-1].should == [ [0]*7 ]*7

  end

  it "mpi_gatherv 8 with tx/rx intersection" do

    res = proc{
            mpi_gatherv [rank+9] , [0,0,0,0,0,0,0,0] , 0 , [0,1,2,3,4,5,6,7] , rank
          }*8

    res.size.should == 8
    res.first.should == (9..16).to_a
    res[1..-1].should == [ [0]*8 ]*7

  end

  it "mpi_gatherv 80" do

    dim = 80
    res = proc{
            mpi_gatherv [rank+9] , [0]*(dim-1) , 0 , 1..(dim-1) , rank
          }*dim

    res.size.should == dim
    res.first.should == (10..(dim+8)).to_a
    res[1..-1].should == [ [0]*(dim-1) ]*(dim-1)

  end

  it "mpi_gatherv 80 with tx/rx intersection" do

    dim = 80
    res = proc{
            mpi_gatherv [rank+9] , [0]*dim , 0 , 0..(dim-1) , rank
          }*dim

    res.size.should == dim
    res.first.should == (9..(dim+8)).to_a
    res[1..-1].should == [ [0]*dim ]*(dim-1)

  end

end
