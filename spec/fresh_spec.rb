require File.expand_path('../spec_helper', __FILE__)

describe "The usage sample from https://github.com/medols/fresh#usage" do

  it "alternates messages from two actors" do

  lambda{

    fresh [

      proc{|id,all|
        3.times{|i|
          sleep 0.25
          puts "Iter #{i+1} from node #{id+1} of #{all} nodes"
          sleep 0.75
        }
      },

      proc{|id,all|
        3.times{|i|
          sleep 0.75 
          puts "Iter #{i+1} from node #{id+1} of #{all} nodes"
          sleep 0.25 
        }
      }

    ]

  }.should output_to_fd(

    "Iter 1 from node 1 of 2 nodes\n"+
    "Iter 1 from node 2 of 2 nodes\n"+
    "Iter 2 from node 1 of 2 nodes\n"+
    "Iter 2 from node 2 of 2 nodes\n"+
    "Iter 3 from node 1 of 2 nodes\n"+
    "Iter 3 from node 2 of 2 nodes\n",

    STDOUT)
  
  end

end

describe "Fresh gather api" do

  it "gathers one integer from three nodes" do

    lambda{

      fresh [

        proc{
          gr2=[1,2,3]
          chc=[0,0]
          msg=[0,0,0]
          mpi_gather_recv gr2 , msg , chc
          puts msg.to_s
        },

        proc{
          gr2=[0]
          msg=[0,10]
          mpi_gather_send gr2 , msg
        },

        proc{
          gr2=[0]
          msg=[1,11]
          mpi_gather_send gr2 , msg
        },

        proc{
          gr2=[0]
          msg=[2,12]
          mpi_gather_send gr2 , msg 
        }

      ]

    }.should output_to_fd(

      "[10, 11, 12]\n",

    STDOUT)
  
  end

  it "broadcasts one integer to three nodes, then gathers this integer from them" do

    lambda{

      fresh [

        proc{
          gr2=[1,2,3]
          ch2=[0,0]
          ms2=[0,0,0]
          mpi_gather_recv gr2 , ms2 , ch2
          puts ms2.to_s
        },

        proc{
          gr1=[4]
          ch1=[0,0]
          ms1=[0]
          gr2=[0]
          ms2=[0,10]
          mpi_gather_recv gr1 , ms1 , ch1
          ms2[1]=ms1[0]
          mpi_gather_send gr2 , ms2
        },

        proc{
          gr1=[4]
          ch1=[0,0]
          ms1=[0]
          gr2=[0]
          ms2=[1,11]
          mpi_gather_recv gr1 , ms1 , ch1
          ms2[1]=ms1[0]
          mpi_gather_send gr2 , ms2
        },

        proc{
          gr1=[4]
          ch1=[0,0]
          ms1=[0]
          gr2=[0]
          ms2=[2,12]
          mpi_gather_recv gr1 , ms1 , ch1
          ms2[1]=ms1[0]
          mpi_gather_send gr2 , ms2
        },

        proc{
          gr1=[1,2,3]
          ms1=[0,32]
          mpi_gather_send gr1 , ms1
        }

      ]

    }.should output_to_fd(

      "[32, 32, 32]\n",

    STDOUT)

  end

  it "broadcasts 0..6 individually to three nodes and gathers them for display" do

    lambda{

      fresh [

        proc{
          7.times{|i|
            gr2=[1,2,3]
            ch2=[0,0]
            ms2=[0,0,0]
            mpi_gather_recv gr2 , ms2 , ch2
            puts ms2.to_s
          }
        },

        proc{
          7.times{|i|
            gr1=[4]
            ch1=[0,0]
            ms1=[0]
            gr2=[0]
            ms2=[0,10]
            mpi_gather_recv gr1 , ms1 , ch1
            ms2[1]=ms1[0]
            mpi_gather_send gr2 , ms2
          }
        },

        proc{
          7.times{|i|
            gr1=[4]
            ch1=[0,0]
            ms1=[0]
            gr2=[0]
            ms2=[1,11]
            mpi_gather_recv gr1 , ms1 , ch1
            ms2[1]=ms1[0]
            mpi_gather_send gr2 , ms2
          }
        },

        proc{
          7.times{|i|
            gr1=[4]
            ch1=[0,0]
            ms1=[0]
            gr2=[0]
            ms2=[2,12]
            mpi_gather_recv gr1 , ms1 , ch1
            ms2[1]=ms1[0]
            mpi_gather_send gr2 , ms2
          }
        },

        proc{
          7.times{|i|
            gr1=[1,2,3]
            ms1=[0,32]
            ms1[1]=i
            mpi_gather_send gr1 , ms1
          }

        }

      ]

    }.should output_to_fd(

      "[0, 0, 0]\n"+
      "[1, 1, 1]\n"+
      "[2, 2, 2]\n"+
      "[3, 3, 3]\n"+
      "[4, 4, 4]\n"+
      "[5, 5, 5]\n"+
      "[6, 6, 6]\n",

    STDOUT)

  end

end

