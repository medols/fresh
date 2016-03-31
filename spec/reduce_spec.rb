require File.expand_path('../spec_helper', __FILE__)

describe "reduce" do

  it "4 nodes" do

    res = proc{ reduce :+ , [rank+9] , [0] , 0 , [1,2,3] }*4
    res.size.should == 4
    res.should == [[33], [0], [0], [0]]

  end

  it "4 nodes with tx/rx intersection" do

    res = proc{
            reduce :+ , [rank+9] , [0] , 0 , [0,1,2,3]
          }*4

    res.size.should == 4
    res.should == [[42], [0], [0], [0]]

  end

  it "4 nodes with default from: and to:" do

    res = proc{ reduce :+ , [rank+9] }*4
    res.size.should == 4
    res.should == [[42], [0], [0], [0]]

  end

  it "4 nodes with defaults and vector" do

    res = proc{ reduce :+ , [rank+9]*4 }*4
    res.size.should == 4
    res.should == [[42]*4, [0]*4, [0]*4, [0]*4]

  end

  it "4 nodes with default to:" do

    res = proc{ reduce :+ , [rank+9] , from:[1,2,3] }*4
    res.size.should == 4
    res.should == [[33], [0], [0], [0]]

  end

  it "4 nodes with default from:" do

    res = proc{ reduce :+ , [rank+9] , to:1 }*4
    res.size.should == 4
    res.should == [[0], [42], [0], [0]]

  end

  it "4 nodes without defaults" do

    res = proc{ reduce :+ , [rank+9] , from:[1,2,3], to:1 }*4
    res.size.should == 4
    res.should == [[0], [33], [0], [0]]

  end

  it "8 nodes" do

    res = proc{
            reduce :+ , [rank+9] , [0] , 0 , [1,2,3,4,5,6,7]
          }*8

    res.size.should == 8
    res.first.should == [ * (10..16).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*7

  end

  it "8 nodes with tx/rx intersection" do

    res = proc{
            reduce :+ , [rank+9] , [0] , 0 , [0,1,2,3,4,5,6,7]
          }*8

    res.size.should == 8
    res.first.should == [ * (9..16).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*7

  end

  it "8 nodes with default from: and to:" do

    res = proc{ reduce :+ , [rank+9] }*8

    res.size.should == 8
    res.first.should == [ * (9..16).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*7

  end

  it "8 nodes with default to:" do

    res = proc{ reduce :+ , [rank+9] , from:[1,2,3,4,5,6,7] }*8
    res.size.should == 8
    res.first.should == [ * (10..16).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*7

  end

  it "NS nodes" do

    dim = NS
    res = proc{
            reduce :+ , [rank+9] , [0] , 0 , 1..(dim-1) 
          }*dim

    res.size.should == dim
    res.first.should == [ * (10..(dim+8)).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*(dim-1)

  end

  it "NS nodes with tx/rx intersection" do

    dim = NS
    res = proc{
            reduce :+ , [rank+9] , [0]*dim , 0 , 0..(dim-1)
          }*dim

    res.size.should == dim
    res.first.should == [ * (9..(dim+8)).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*(dim-1)

  end

  it "NS nodes with default from: and to:" do

    dim = NS
    res = proc{ reduce :+ , [rank+9] }*dim
    res.size.should == dim
    res.first.should == [ * (9..(dim+8)).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*(dim-1)

  end

  it "NS nodes with default to:" do

    dim = NS
    res = proc{ reduce :+ , [rank+9] , from:1..(dim-1) }*dim
    res.size.should == dim
    res.first.should == [ * (10..(dim+8)).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*(dim-1)

  end

  it "4 nodes array method" do

    res = proc{ [rank+9].areduce :+ , [0] , 0 , [1,2,3] }*4
    res.size.should == 4
    res.should == [[33], [0], [0], [0]]

  end

  it "4 nodes array method with tx/rx intersection" do

    res = proc{
            [rank+9].areduce :+ , [0] , 0 , [0,1,2,3]
          }*4

    res.size.should == 4
    res.should == [[42], [0], [0], [0]]

  end

  it "4 nodes array method with default from: and to:" do

    res = proc{ [rank+9].areduce :+ }*4
    res.size.should == 4
    res.should == [[42], [0], [0], [0]]

  end

  it "4 nodes array method with defaults and vector" do

    res = proc{ ([rank+9]*4).areduce :+ }*4
    res.size.should == 4
    res.should == [[42]*4, [0]*4, [0]*4, [0]*4]

  end

  it "4 nodes array method with default to:" do

    res = proc{ [rank+9].areduce :+ , from:[1,2,3] }*4
    res.size.should == 4
    res.should == [[33], [0], [0], [0]]

  end

  it "4 nodes array method with default from:" do

    res = proc{ [rank+9].areduce :+ , to:1 }*4
    res.size.should == 4
    res.should == [[0], [42], [0], [0]]

  end

  it "4 nodes array method without defaults" do

    res = proc{ [rank+9].areduce :+ , from:[1,2,3], to:1 }*4
    res.size.should == 4
    res.should == [[0], [33], [0], [0]]

  end

  it "8 nodes array method" do

    res = proc{
            [rank+9].areduce :+ , [0] , 0 , [1,2,3,4,5,6,7]
          }*8

    res.size.should == 8
    res.first.should == [ * (10..16).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*7

  end

  it "8 nodes array method with tx/rx intersection" do

    res = proc{
            [rank+9].areduce :+ , [0] , 0 , [0,1,2,3,4,5,6,7]
          }*8

    res.size.should == 8
    res.first.should == [ * (9..16).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*7

  end

  it "8 nodes array method with default from: and to:" do

    res = proc{ [rank+9].areduce :+ }*8

    res.size.should == 8
    res.first.should == [ * (9..16).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*7

  end

  it "8 nodes array method with default to:" do

    res = proc{ [rank+9].areduce :+ , from:[1,2,3,4,5,6,7] }*8
    res.size.should == 8
    res.first.should == [ * (10..16).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*7

  end

  it "NS nodes array method" do

    dim = NS
    res = proc{
            [rank+9].areduce :+ , [0] , 0 , 1..(dim-1) 
          }*dim

    res.size.should == dim
    res.first.should == [ * (10..(dim+8)).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*(dim-1)

  end

  it "NS nodes array method with tx/rx intersection" do

    dim = NS
    res = proc{
            [rank+9].areduce :+ , [0]*dim , 0 , 0..(dim-1)
          }*dim

    res.size.should == dim
    res.first.should == [ * (9..(dim+8)).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*(dim-1)

  end

  it "NS nodes array method with default from: and to:" do

    dim = NS
    res = proc{ [rank+9].areduce :+ }*dim
    res.size.should == dim
    res.first.should == [ * (9..(dim+8)).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*(dim-1)

  end

  it "NS nodes array method with default to:" do

    dim = NS
    res = proc{ [rank+9].areduce :+ , from:1..(dim-1) }*dim
    res.size.should == dim
    res.first.should == [ * (10..(dim+8)).to_a.reduce(:+) ]
    res[1..-1].should == [ [0] ]*(dim-1)

  end

end
