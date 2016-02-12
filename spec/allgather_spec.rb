require File.expand_path('../spec_helper', __FILE__)

describe "allgather" do

  it "4 nodes" do

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

  it "8 nodes" do

    res = proc{
            val=[[],[],[], [], (1..7).to_a, (11..17).to_a, (21..27).to_a, (31..37).to_a]
            7.times.map{|i|
              allgather [val[rank][i]] , [0]*4 , 4..7 , 0..3 
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

  it "90 nodes" do

    dim = 90
    dim2= dim/2
    res = proc{
            val=([[]]*dim2).concat dim2.times.map{|i| ((1+(10*i))..(7+(10*i))).to_a}
            7.times.map{|i|
              allgather [val[rank][i]] , [0]*dim2 , dim2..(dim-1) , 0..(dim2-1) 
            }
          }*dim

    res.size.should == dim
    res[0..(dim2-1)].each{|r| r.should == (1..7).map{|i| (i..(i+10*(dim2-1))).step(10).to_a} }
    res[dim2..(dim-1)].should == [[[0]*dim2]*7]*dim2

  end

end
