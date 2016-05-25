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

  it "values + allgather + product + gather + product with array methods" do
    val=[[4,2,3,8,4,6,1],[2,4,8,16,32,64,48]]*3
    coef=[0,1,2,1,2,1,2,3,2,3,2,0,0]

    (proc{
      7.times.map{|i|
        [ coef[2*rank,2] * [val[rank][i]].allgather( from:[4,5] , to:[1,2,3] ) ].gather(from:[1,2,3]) * coef[8,3]
      }
    }*6).first.should == [78, 72, 130, 288, 408, 788, 542]
  end

  it "line fit" do

    XY =[
      [   3.246660,   3.217080,   3.187500,   3.157919,   3.128339,   3.098758,   3.069178,   3.039597,   3.010017,   2.980436],
      [  -0.572929,  -0.352684,  -0.132440,   0.087805,   0.308050,   0.528294,   0.748539,   0.968784,   1.189028,   1.409273]
    ]

    res=proc{     
      xyc = [ XY[rank].sum / XY[rank].size ].allgather
      dXY = [ XY[rank].dot( :-, xyc[rank]) ].allgather
      numdenom = [ 
        0.(){ -2 * (dXY[0]*dXY[1]) } || 
        1.(){ 
          x2 = dXY[0].dot(:**,2)
          y2 = dXY[1].dot(:**,2) 
          y2.dot(:-,x2).sum 
        }].allgather
      alpha = atan2(numdenom[0] , numdenom[1]) / 2
      r = xyc * [ cos(alpha) , sin(alpha) ]
      [alpha,r]
    }*2
    res.first.should == [0.13350834495469482, 3.141504649165192]

  end

end

