describe "Usage group" do

  it "Usage example" do

    fresh [

      proc{|id,all|
        7.times{|i|
          puts "Iter #{i+1} from node #{id+1} of #{all} nodes"
          sleep 1
        }
      },

      proc{|id,all|
        7.times{|i|
          sleep 0.5 
          puts "Iter #{i+1} from node #{id+1} of #{all} nodes"
          sleep 0.5 
        }
      }

    ]
  
  end

end

