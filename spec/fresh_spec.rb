require File.expand_path('../spec_helper', __FILE__)

describe "proc mpi api" do

  it "multiple node exception" do
    lambda { proc{ raise }*4 }.should raise_error(MultiNodeError)
  end

  it "bcast then gather" do

    [[32,32,32], [0,0,0], [0,0,0], [0,0,0], [0,0,0]].should ==

    proc{
      val=bcast [32] , [0] , 4 , [1,2,3]
      gather val , [0,0,0] , 0 , [1,2,3] 
    }*5

  end

  it "bcastv then gatherv inside loop" do
    (proc{
      7.times.map{|i|
        buf= bcast [i] , [0] , 4 , [1,2,3] 
        gather buf , [0,0,0] , 0 , [1,2,3]
      }
    }*5).first.should == [[0,0,0], [1,1,1], [2,2,2], [3,3,3], [4,4,4], [5,5,5], [6,6,6]]
  end

  it "bcastv then signal processing then gatherv" do
    (proc{
      val=[4,2,3,8,4,6,1]
      coef=[1,2,1,2,1,2,3,2,3,2,0,0]
      7.times.map{|i|
        buf1=bcast [val[i]] , [0] , 4 , [1,2,3] 
        buf2=gather [ buf1[0]*coef[2*rank-1] ] , [0,0,0] , 0 , [1,2,3]
        buf2[0]*coef[7] + buf2[1]*coef[8] + buf2[2]*coef[9]
      }
    }*5).first.should == [56, 28, 42, 112, 56, 84, 14]
  end

  it "allgatherv then processign then gatherv" do
    (proc{
      val=[[], [], [], [], [ 4, 2, 3, 8, 4, 6, 1], [ 2, 4, 8,16,32,64,48]]
      coef=[1,2,1,2,1,2,3,2,3,2,0,0]

      7.times.map{|i|
        rbuf1=allgather [val[rank][i]] , [0,0] , [1,2,3] , [4,5]
        rbuf2=gather [rbuf1[0]*coef[2*rank-1] + rbuf1[1]*coef[2*rank]] , [0,0,0] , 0 , [1,2,3]
        rbuf2[0]*coef[7] + rbuf2[1]*coef[8] + rbuf2[2]*coef[9]
      }
    }*6).first.should == [78, 72, 130, 288, 408, 788, 542]
  end

  it "values + allgather + product + gather + product " do
    (proc{
      val=[[4,2,3,8,4,6,1],[2,4,8,16,32,64,48]]*3
      coef=[0,1,2,1,2,1,2,3,2,3,2,0,0]

      7.times.map{|i|
        buf = coef[2*rank,2] * allgather( [val[rank][i]] , from:[4,5] , to:[1,2,3] )
        coef[8,3] * gather([ buf ] , from:[1,2,3])
      }
    }*6).first.should == [78, 72, 130, 288, 408, 788, 542]
  end

end

