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
          mpi_gather chc , msg , gr2
          puts msg.to_s
        },

        proc{
          gr2=[0]
          msg=[0,10]
          mpi_bcast msg , gr2
        },

        proc{
          gr2=[0]
          msg=[1,11]
          mpi_bcast msg , gr2
        },

        proc{
          gr2=[0]
          msg=[2,12]
          mpi_bcast msg , gr2 
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
          mpi_gather ch2 , ms2 , gr2
          puts ms2.to_s
        },

        proc{
          gr1=[4]
          ch1=[0,0]
          ms1=[0]
          gr2=[0]
          ms2=[0,10]
          mpi_gather ch1 , ms1 , gr1
          ms2[1]=ms1[0]
          mpi_bcast ms2 , gr2
        },

        proc{
          gr1=[4]
          ch1=[0,0]
          ms1=[0]
          gr2=[0]
          ms2=[1,11]
          mpi_gather ch1 , ms1 , gr1
          ms2[1]=ms1[0]
          mpi_bcast ms2 , gr2
        },

        proc{
          gr1=[4]
          ch1=[0,0]
          ms1=[0]
          gr2=[0]
          ms2=[2,12]
          mpi_gather ch1 , ms1 , gr1
          ms2[1]=ms1[0]
          mpi_bcast ms2 , gr2
        },

        proc{
          gr1=[1,2,3]
          ms1=[0,32]
          mpi_bcast ms1 , gr1
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
            mpi_gather ch2 , ms2 , gr2
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
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]
            mpi_bcast ms2 , gr2
          }
        },

        proc{
          7.times{|i|
            gr1=[4]
            ch1=[0,0]
            ms1=[0]
            gr2=[0]
            ms2=[1,11]
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]
            mpi_bcast ms2 , gr2
          }
        },

        proc{
          7.times{|i|
            gr1=[4]
            ch1=[0,0]
            ms1=[0]
            gr2=[0]
            ms2=[2,12]
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]
            mpi_bcast ms2 , gr2
          }
        },

        proc{
          7.times{|i|
            gr1=[1,2,3]
            ms1=[0,32]
            ms1[1]=i
            mpi_bcast ms1 , gr1
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

  it "broadcasts vector values individually to three computing nodes and gathers them for display after processing" do

    lambda{

      fresh [

        proc{
          7.times{|i|
            coef=[1,2,1,2,1,2,3,2,3,2]
            val=[0]
            gr2=[1,2,3]
            ch2=[0,0]
            ms2=[0,0,0]
            mpi_gather ch2 , ms2 , gr2
            val[0] = ms2[0]*coef[7] + ms2[1]*coef[8] + ms2[2]*coef[9]
            puts val.to_s
          }
        },

        proc{
          7.times{|i|
            coef=[1,2,1,2,1,2,3,2,3,2]
            gr1=[4]
            ch1=[0,0]
            ms1=[0]
            gr2=[0]
            ms2=[0,10]
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]*coef[1]
            mpi_bcast ms2 , gr2
          }
        },

        proc{
          7.times{|i|
            coef=[1,2,1,2,1,2,3,2,3,2]
            gr1=[4]
            ch1=[0,0]
            ms1=[0]
            gr2=[0]
            ms2=[1,11]
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]*coef[3]
            mpi_bcast ms2 , gr2
          }
        },

        proc{
          7.times{|i|
            coef=[1,2,1,2,1,2,3,2,3,2]
            gr1=[4]
            ch1=[0,0]
            ms1=[0]
            gr2=[0]
            ms2=[2,12]
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]*coef[5]
            mpi_bcast ms2 , gr2
          }
        },

        proc{
          7.times{|i|
            gr1=[1,2,3]
            ms1=[0,32]
            val=[4,2,3,8,4,6,1]
            ms1[1]=val[i]
            mpi_bcast ms1 , gr1
          }
        }

      ]

    }.should output_to_fd(

      "[56]\n"+
      "[28]\n"+
      "[42]\n"+
      "[112]\n"+
      "[56]\n"+
      "[84]\n"+
      "[14]\n",

    STDOUT)

  end

   it "broadcasts two vector values individually from two generators to three processing nodes and gathers them for display after further computations" do

    lambda{
     
      fresh [
        proc{
          7.times{|i|
            coef=[1,2,1,2,1,2,3,2,3,2]
            val=[0]
            gr2=[1,2,3]
            ch2=[0,0]
            ms2=[0,0,0]
            mpi_gather ch2 , ms2 , gr2
            val[0] = ms2[0]*coef[7] + ms2[1]*coef[8] + ms2[2]*coef[9]
            puts val.to_s
          }
        },
        proc{
          7.times{|i|
            coef=[1,2,1,2,1,2,3,2,3,2]
            gr1=[4,5]
            ch1=[0,0]
            ms1=[0,0]
            gr2=[0]
            ms2=[0,10]
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]*coef[1]+ms1[1]*coef[2]
            mpi_bcast ms2 , gr2
          }
        },
        proc{
          7.times{|i|
            coef=[1,2,1,2,1,2,3,2,3,2]
            gr1=[4,5]
            ch1=[0,0]
            ms1=[0,0]
            gr2=[0]
            ms2=[1,11]
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]*coef[3]+ms1[1]*coef[4]
            mpi_bcast ms2 , gr2
          }
        },
        proc{
          7.times{|i|
            coef=[1,2,1,2,1,2,3,2,3,2]
            gr1=[4,5]
            ch1=[0,0]
            ms1=[0,0]
            gr2=[0]
            ms2=[2,12]
            mpi_gather ch1 , ms1 , gr1
            ms2[1]=ms1[0]*coef[5]+ms1[1]*coef[6]
            mpi_bcast ms2 , gr2
          }
        },
        proc{
          7.times{|i|
            val=[4,2,3,8,4,6,1]
            gr1=[1,2,3]
            ms1=[0,32]
            ms1[1]=val[i]
            mpi_bcast ms1 , gr1
          }
        },
        proc{
          7.times{|i|
            val=[2,4,8,16,32,64,48]
            gr1=[1,2,3]
            ms1=[1,32]
            ms1[1]=val[i]
            mpi_bcast ms1 , gr1
          }
        }
      
      ]

     }.should output_to_fd(

      "[78]\n"+
      "[72]\n"+
      "[130]\n"+
      "[288]\n"+
      "[408]\n"+
      "[788]\n"+
      "[542]\n",

    STDOUT)

  end

end
     
