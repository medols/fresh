require File.expand_path('../spec_helper', __FILE__)

describe "proc mpi api" do

  it "mpi_init 2" do
    ( proc{ 2 }*2 ).should == [2,2]
  end

  it "mpi_init 4" do
    ( proc{ 4 }*4 ).should == [4,4,4,4]
  end

  it "mpi_init 100" do
    ( proc{ 100 }*100 ).should == [100]*100
  end

  it "mpi_rank 2" do
    ( proc{ |rank,size| rank }*2 ).should == [0,1]
  end

  it "mpi_rank 4" do
    ( proc{ |rank,size| rank }*4 ).should == [0,1,2,3]
  end

  it "mpi_rank 100" do
    ( proc{ |rank,size| rank }*100 ).should == 100.times.to_a
  end

  it "mpi_size 2" do
    ( proc{ |rank,size| size }*2 ).should == [2,2]
  end

  it "mpi_size 4" do
    ( proc{ |rank,size| size }*4 ).should == [4,4,4,4]
  end

  it "mpi_size 100" do
    ( proc{ |rank,size| size }*100 ).should == [100]*100
  end

  it "mpi_bcastv" do
    ( 

      proc{ |rank,size|
        mpi_bcastv [32] , [0] , 0 , [1,2,3] , rank
      }*4 

    ).should == [[0], [32], [32], [32]]
  end

  it "mpi_gatherv" do

    [[10,11,12], [0,0,0], [0,0,0], [0,0,0]].should ==

    proc{ |rank,size|
      mpi_gatherv [rank+9] , [0,0,0] , 0 , [1,2,3] , rank
    }*4

  end

  it "mpi_scatterv" do

    [[0], [3], [2], [1]].should ==

    proc{ |rank,size|
      mpi_scatterv [3,2,1] , [0] , 0 , [1,2,3] , rank
    }*4

  end

  it "mpi_bcastv then mpi_gatherv" do

    [[32,32,32], [0,0,0], [0,0,0], [0,0,0], [0,0,0]].should ==

    proc{ |rank,size|
      val=mpi_bcastv [32] , [0] , 4 , [1,2,3] , rank
      mpi_gatherv val , [0,0,0] , 0 , [1,2,3] , rank 
    }*5

  end

  it "loop bcastv then gatherv" do
    (proc{ |rank,size|
      7.times.map{|i|
        buf= mpi_bcastv [i] , [0] , 4 , [1,2,3] , rank
        mpi_gatherv buf , [0,0,0] , 0 , [1,2,3] , rank
      }
    }*5).first.should == [[0,0,0], [1,1,1], [2,2,2], [3,3,3], [4,4,4], [5,5,5], [6,6,6]]
  end

  it "bcastv to signal processing then gatherv" do
    (proc{ |rank,size|
      val=[4,2,3,8,4,6,1]
      coef=[1,2,1,2,1,2,3,2,3,2,0,0]
      7.times.map{|i|
        buf1=mpi_bcastv [val[i]] , [0] , 4 , [1,2,3] , rank
        buf2=mpi_gatherv [ buf1[0]*coef[2*rank-1] ] , [0,0,0] , 0 , [1,2,3] , rank
        buf2[0]*coef[7] + buf2[1]*coef[8] + buf2[2]*coef[9]
      }
    }*5).first.should == [56, 28, 42, 112, 56, 84, 14]
  end

  it "allgatherv" do
    (proc{ |rank,size|
      val=[[], [], [], [ 4, 2, 3, 8, 4, 6, 1], [ 2, 4, 8,16,32,64,48]]
      7.times.map{|i|
        mpi_allgatherv [val[rank][i]] , [0,0] , [3,4] , [0,1,2] , rank
      }
    }*5)[0..2].should == [
      [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]], 
      [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]], 
      [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]]
    ] 
  end

  it "first allgatherv then processign with gatherv" do
    (proc{ |rank,size|
      val=[[], [], [], [], [ 4, 2, 3, 8, 4, 6, 1], [ 2, 4, 8,16,32,64,48]]
      coef=[1,2,1,2,1,2,3,2,3,2,0,0]

      7.times.map{|i|
        rbuf1=mpi_allgatherv [val[rank][i]] , [0,0] , [4,5] , [1,2,3] , rank
        rbuf2=mpi_gatherv [rbuf1[0]*coef[2*rank-1] + rbuf1[1]*coef[2*rank]] , [0,0,0] , 0 , [1,2,3] , rank
        rbuf2[0]*coef[7] + rbuf2[1]*coef[8] + rbuf2[2]*coef[9]
      }
    }*6).first.should == [78, 72, 130, 288, 408, 788, 542]
  end

end

