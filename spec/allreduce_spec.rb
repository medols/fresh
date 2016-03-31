require File.expand_path('../spec_helper', __FILE__)

describe "allreduce" do

  it "4 nodes" do

    res = proc{
            val=[[], [], [*(1..7)], [*(11..17)] ]
            7.times.map{|i|
              allreduce :+,  [val[rank][i]] , [0,0] , [0,1], [2,3] 
            }
          }*4

    res.size.should == 4
    res[0].should == ([*1..7].zip([*11..17])).map{|v| [v.reduce(:+)]}
    res[1].should == ([*1..7].zip([*11..17])).map{|v| [v.reduce(:+)]}
    res[2].should == [[0]]*7
    res[3].should == [[0]]*7

  end

  it "4 nodes with tx/rx intersection" do

    res = proc{
            val=[[], [], [*1..7], [*11..17] ]
            7.times.map{|i|
              allreduce :+,  [val[rank][i]] , [0,0,0] , [0,1,2] , [2,3]
            }
          }*4

    res.size.should == 4
    res[0].should == ([*1..7].zip([*11..17])).map{|v| [v.reduce(:+)]}
    res[1].should == ([*1..7].zip([*11..17])).map{|v| [v.reduce(:+)]}
    res[2].should == ([*1..7].zip([*11..17])).map{|v| [v.reduce(:+)]}
    res[3].should == [[0]]*7

  end

  it "4 nodes without defaults" do

    res = proc{
            val=[[], [], [*(1..7)], [*(11..17)] ]
            7.times.map{|i|
              allreduce :+,  [val[rank][i]] , from:2..3 , to:0..1
            }
          }*4

    res.size.should == 4
    res[0].should == ([*1..7].zip([*11..17])).map{|v| [v.reduce(:+)]}
    res[1].should == ([*1..7].zip([*11..17])).map{|v| [v.reduce(:+)]}
    res[2].should == [[0]]*7
    res[3].should == [[0]]*7

  end

  it "8 nodes" do

    res = proc{
            val=[[],[],[], [], [*1..7], [*11..17], [*21..27], [*31..37] ]
            7.times.map{|i|
              allreduce :+,  [val[rank][i]] , [0]*4 , 0..3, 4..7 
            }
          }*8

    res.size.should == 8
    res[0].should == [[[1, 11, 21, 31].reduce(:+)],
                      [[2, 12, 22, 32].reduce(:+)],
                      [[3, 13, 23, 33].reduce(:+)],
                      [[4, 14, 24, 34].reduce(:+)],
                      [[5, 15, 25, 35].reduce(:+)],
                      [[6, 16, 26, 36].reduce(:+)],
                      [[7, 17, 27, 37].reduce(:+)]]
    res[1].should == res[0]
    res[2].should == res[0]
    res[3].should == res[0]
    res[4].should == [[0]]*7
    res[5].should == [[0]]*7
    res[6].should == [[0]]*7
    res[7].should == [[0]]*7

  end

  it "8 nodes with tx/rx intersection" do

    res = proc{
            val=[[],[],[], [], [*1..7], [*11..17], [*21..27], [*31..37] ]
            7.times.map{|i|
              allreduce :+,  [val[rank][i]] , [0]*5 , 0..4 , 4..7 
            }
          }*8

    res.size.should == 8
    res[0].should == [[[1, 11, 21, 31].reduce(:+)],
                      [[2, 12, 22, 32].reduce(:+)],
                      [[3, 13, 23, 33].reduce(:+)],
                      [[4, 14, 24, 34].reduce(:+)],
                      [[5, 15, 25, 35].reduce(:+)],
                      [[6, 16, 26, 36].reduce(:+)],
                      [[7, 17, 27, 37].reduce(:+)]]
    res[1].should == res[0]
    res[2].should == res[0]
    res[3].should == res[0]
    res[4].should == res[0]
    res[5].should == [[0]]*7
    res[6].should == res[5] 
    res[7].should == res[5] 

  end

  it "NS nodes" do

    dim = NS
    dim2= dim/2
    res = proc{
            val=([[]]*dim2).concat dim2.times.map{|i| ((1+(10*i))..(7+(10*i))).to_a}
            7.times.map{|i|
              allreduce :+,  [val[rank][i]] , [0]*dim2 , 0..(dim2-1) , dim2..(dim-1) 
            }
          }*dim

    res.size.should == dim
    res[0..(dim2-1)].each{|r| r.should == (1..7).map{|i| [(i..(i+10*(dim2-1))).step(10).to_a.reduce(:+)] } }
    res[dim2..(dim-1)].should == [[[0]]*7]*dim2

  end

  it "NS nodes with tx/rx intersection" do

    dim = NS
    dim2= dim/2
    res = proc{
            val=([[]]*dim2).concat dim2.times.map{|i| ((1+(10*i))..(7+(10*i))).to_a}
            7.times.map{|i|
              allreduce :+,  [val[rank][i]] , [0]*(dim2+1) , 0..(dim2) , dim2..(dim-1)
            }
          }*dim

    res.size.should == dim
    res[0..dim2].each{|r| r.should == (1..7).map{|i| [(i..(i+10*(dim2-1))).step(10).to_a.reduce(:+)] } }
    res[(dim2+1)..(dim-1)].should == [[[0]]*7]*(dim2-1)

  end

end
