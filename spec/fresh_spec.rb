require File.expand_path('../spec_helper', __FILE__)

describe "proc mpi api" do

  it "mpi_gatherv" do

    (proc{|rank,size|
      sbuf=[rank+9]
      rbuf=[0,0,0]
      root=0
      comm=[1,2,3]

      mpi_gatherv sbuf , rbuf , root , comm , rank
      rbuf
    }*4).should==[[10,11,12],[0,0,0],[0,0,0],[0,0,0]]

  end

  it "mpi_bcastv" do
    (proc{|rank,size|
          sbuf=[32]
          rbuf=[0]
          root=0
          comm=[1,2,3]

          mpi_bcastv sbuf , rbuf , root , comm , rank
          rbuf
    }*4).should == [[0], [32], [32], [32]]
  end

  it "first mpi_bcastv then mpi_gatherv" do
    (proc{ |rank,size|
      sbuf1=[32]
      rbuf1=[0]
      root1=4
      comm1=[1,2,3]

      mpi_bcastv sbuf1 , rbuf1 , root1 , comm1 , rank 

      sbuf2=[0]
      rbuf2=[0,0,0]
      root2=0
      comm2=[1,2,3]

      sbuf2[0]=rbuf1[0]
      mpi_gatherv sbuf2 , rbuf2 , root2 , comm2 , rank 
      rbuf2
    }*5).should == [
      [32, 32, 32], 
      [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]
    ]
  end

  it "first bcastv then gatherv loop" do
    (proc{ |rank,size|
      7.times.map{|i|
        sbuf1=[0]
        rbuf1=[0]
        root1=4
        comm1=[1,2,3]

        sbuf1[0]=i
        mpi_bcastv sbuf1 , rbuf1 , root1 , comm1 , rank 

        sbuf2=[0]
        rbuf2=[0,0,0]
        root2=0
        comm2=[1,2,3]

        sbuf2[0]=rbuf1[0]
        mpi_gatherv sbuf2 , rbuf2 , root2 , comm2 , rank 
        rbuf2
      }
    }*5).first.should == [
      [0, 0, 0], [1, 1, 1], [2, 2, 2], [3, 3, 3], 
      [4, 4, 4], [5, 5, 5], [6, 6, 6]
    ]
  end

  it "first bcastv then signal processing with gatherv" do
    (proc{ |rank,size|
      7.times.map{|i|
        sbuf1=[0]
        rbuf1=[0]
        root1=4
        comm1=[1,2,3]

        val=[4,2,3,8,4,6,1]
        sbuf1[0]=val[i]
        mpi_bcastv sbuf1 , rbuf1 , root1 , comm1 , rank 

        sbuf2=[0]
        rbuf2=[0,0,0]
        root2=0
        comm2=[1,2,3]

        coef=[1,2,1,2,1,2,3,2,3,2]
        val=[0]

        sbuf2[0]=rbuf1[0]*coef[1+(rank-1)*2]
        mpi_gatherv sbuf2 , rbuf2 , root2 , comm2 , rank 

        val[0] = rbuf2[0]*coef[7] + rbuf2[1]*coef[8] + rbuf2[2]*coef[9]
        val
      }
    }*5).first.should == [[56], [28], [42], [112], [56], [84], [14]]
  end

  it "allgatherv" do
    (proc{|rank,size|
      7.times.map{|i|
        sbuf=[32]
        rbuf=[0,0]
        root=[3,4]
        comm=[0,1,2]

        val1=[4,2,3,8,4,6,1]
        val2=[2,4,8,16,32,64,48]
        sbuf[0]=val1[i] if rank == 3
        sbuf[0]=val2[i] if rank == 4
        mpi_allgatherv sbuf , rbuf , root , comm , rank
        rbuf
      }
    }*5)[0..2].should == [
      [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]], 
      [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]], 
      [[4, 2], [2, 4], [3, 8], [8, 16], [4, 32], [6, 64], [1, 48]]
    ] 
  end

  it "first allgatherv then processign with gatherv" do
    (proc{ |rank,size|
      7.times.map{|i|
        coef=[1,2,1,2,1,2,3,2,3,2]
        val0=[0]
        val1=[4,2,3,8,4,6,1]
        val2=[2,4,8,16,32,64,48]

        sbuf1=[0]
        rbuf1=[0,0]
        root1=[4,5]
        comm1=[1,2,3]

        sbuf1[0]=val1[i] if rank==4
        sbuf1[0]=val2[i] if rank==5
        mpi_allgatherv sbuf1 , rbuf1 , root1 , comm1 , rank

        sbuf2=[0]
        rbuf2=[0,0,0]
        root2=0
        comm2=[1,2,3]

        sbuf2[0]=rbuf1[0]*coef[2*rank-1]+rbuf1[1]*coef[2*rank] if comm2.include? rank
        mpi_gatherv sbuf2 , rbuf2 , root2 , comm2 , rank

        val0[0] = rbuf2[0]*coef[7] + rbuf2[1]*coef[8] + rbuf2[2]*coef[9]
        val0
      }
    }*6).first.should == [[78], [72], [130], [288], [408], [788], [542]]

  end

end

