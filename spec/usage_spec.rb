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

