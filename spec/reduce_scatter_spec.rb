require File.expand_path('../spec_helper', __FILE__)

describe "reduce_scatter" do

  it "4 nodes" do

    res = proc{ reduce_scatter :+ , [rank+9]*3 , [0] , 0 , [1,2,3] }*4
    res.size.should == 4
    res.should == [[0], [33], [33], [33]]

  end

  it "4 nodes with tx/rx intersection" do

    res = proc{
            reduce_scatter :+ , [rank+9]*4 , [0] , 0 , [0,1,2,3]
          }*4

    res.size.should == 4
    res.should == [[42], [42], [42], [42]]

  end

  it "4 nodes with default from: and to:" do

    res = proc{ reduce_scatter :+ , [rank+9]*4 }*4
    res.size.should == 4
    res.should == [[42], [42], [42], [42]]

  end

  it "4 nodes with defaults and vector" do

    res = proc{ reduce_scatter :+ , [rank+9]*8 }*4
    res.size.should == 4
    res.should == [[42]*2]*4

  end


#  it "4 nodes with default to:" do
#
#    res = proc{ reduce_scatter :+ , [rank+9] , from:[1,2,3] }*4
#    res.size.should == 4
#    res.should == [[33], [0], [0], [0]]
#
#  end

#  it "4 nodes with default from:" do
#
#    res = proc{ reduce_scatter :+ , [rank+9]*4 , to:1 }*4
#    res.size.should == 4
#    res.should == [[0], [42], [0], [0]]
#
#  end

#  it "4 nodes without defaults" do
#
#    res = proc{ reduce_scatter :+ , [rank+9] , from:[1,2,3], to:1 }*4
#    res.size.should == 4
#    res.should == [[0], [33], [0], [0]]
#
#  end

#  it "8 nodes" do
#
#    res = proc{
#            reduce_scatter :+ , [rank+9] , [0] , 0 , [1,2,3,4,5,6,7]
#          }*8
#
#    res.size.should == 8
#    res.first.should == [ * (10..16).to_a.reduce_scatter(:+) ]
#    res[1..-1].should == [ [0] ]*7
#
#  end

  it "8 nodes with tx/rx intersection" do

    res = proc{
            reduce_scatter :+ , [rank+9]*8 , [0] , 0 , [0,1,2,3,4,5,6,7]
          }*8

    res.size.should == 8
    res.should == [ [ * (9..16).to_a.reduce(:+) ] ]*8

  end

  it "8 nodes with default from: and to:" do

    res = proc{ reduce_scatter :+ , [rank+9]*8 }*8

    res.size.should == 8
    res.should == [ [ * (9..16).to_a.reduce(:+) ] ]*8

  end

#  it "8 nodes with default to:" do
#
#    res = proc{ reduce_scatter :+ , [rank+9] , from:[1,2,3,4,5,6,7] }*8
#    res.size.should == 8
#    res.first.should == [ * (10..16).to_a.reduce_scatter(:+) ]
#    res[1..-1].should == [ [0] ]*7
#
#  end

#  it "100 nodes" do
#
#    dim = 100
#    res = proc{
#            reduce_scatter :+ , [rank+9] , [0] , 0 , 1..(dim-1) 
#          }*dim
#
#    res.size.should == dim
#    res.first.should == [ * (10..(dim+8)).to_a.reduce_scatter(:+) ]
#    res[1..-1].should == [ [0] ]*(dim-1)
#
#  end

  it "100 nodes with tx/rx intersection" do

    dim = 100
    res = proc{
            reduce_scatter :+ , [rank+9]*dim , [0] , 0 , 0...dim
          }*dim

    res.size.should == dim
    res.should == [ [ * (9..(dim+8)).to_a.reduce(:+) ] ]*dim

  end

  it "100 nodes with default from: and to:" do

    dim = 100
    res = proc{ reduce_scatter :+ , [rank+9]*dim }*dim
    res.size.should == dim
    res.should == [ [ * (9..(dim+8)).to_a.reduce(:+) ] ]*dim

  end

#  it "100 nodes with default to:" do
#
#    dim = 100
#    res = proc{ reduce_scatter :+ , [rank+9] , from:1..(dim-1) }*dim
#    res.size.should == dim
#    res.first.should == [ * (10..(dim+8)).to_a.reduce_scatter(:+) ]
#    res[1..-1].should == [ [0] ]*(dim-1)
#
#  end

end
