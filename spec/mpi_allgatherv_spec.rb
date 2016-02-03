describe "mpi_allgatherv" do

  it "mpi_allgatherv 4" do

    res = proc{
            val=[[], [], (1..7).to_a, (11..17).to_a]
            7.times.map{|i|
              mpi_allgatherv [val[rank][i]] , [0,0] , [2,3] , [0,1] , rank
            }
          }*4

    res.size.should == 4
    res[0].should == [[1, 11], [2, 12], [3, 13], [4, 14], [5, 15], [6, 16], [7, 17]]
    res[1].should == res[0]
    res[2].should == [[0, 0], [0, 0], [0, 0], [0,  0], [0,  0], [0,  0], [0,  0]]
    res[3].should == res[2] 

  end

  it "allgather 4" do

    res = proc{
            val=[[], [], (1..7).to_a, (11..17).to_a]
            7.times.map{|i|
              allgather [val[rank][i]] , [0,0] , [2,3] , [0,1]
            }
          }*4

    res.size.should == 4
    res[0].should == [[1, 11], [2, 12], [3, 13], [4, 14], [5, 15], [6, 16], [7, 17]]
    res[1].should == res[0]
    res[2].should == [[0, 0], [0, 0], [0, 0], [0,  0], [0,  0], [0,  0], [0,  0]]
    res[3].should == res[2] 

  end

  it "mpi_allgatherv 8" do

    res = proc{
            val=[[],[],[], [], (1..7).to_a, (11..17).to_a, (21..27).to_a, (31..37).to_a]
            7.times.map{|i|
              mpi_allgatherv [val[rank][i]] , [0]*4 , 4..7 , 0..3 , rank
            }
          }*8

    res.size.should == 8
    res[0].should == [[1, 11, 21, 31],
                      [2, 12, 22, 32],
                      [3, 13, 23, 33],
                      [4, 14, 24, 34],
                      [5, 15, 25, 35],
                      [6, 16, 26, 36],
                      [7, 17, 27, 37]]
    res[1].should == res[0]
    res[2].should == res[0]
    res[3].should == res[0]
    res[4].should == [[0, 0, 0, 0]]*7
    res[5].should == res[4] 
    res[6].should == res[4] 
    res[7].should == res[4] 

  end

  it "mpi_allgatherv 100" do

    res = proc{
            val=([[]]*50).concat 50.times.map{|i| ((1+(10*i))..(7+(10*i))).to_a}
            7.times.map{|i|
              mpi_allgatherv [val[rank][i]] , [0]*50 , 50..99 , 0..49 , rank
            }
          }*100

    res.size.should == 100
    res[0..49].each{|r| r.should == (1..7).map{|i| (i..(i+10*(50-1))).step(10).to_a} }
    res[50..99].should == [[[0]*50]*7]*50 

  end

end
