# fresh-mc.rb - Fresh gem for multi-core processing. 
#
# Copyright 2015-2016  Jaume Masip-Torne <jmasip@gianduia.net>
#           2015-2016  Ismael Merodio-Codinachs <ismael@gianduia.net>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the owners nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'rubinius/actor'

class Fresh < Rubinius::Actor 

  extend Rubinius

  attr_accessor :rank
  attr_accessor :size

  def linked
    @links
  end

  def mpi_gather sbuf , rbuf, comm
    comm.each{
      sbuf=Rubinius::Actor.receive{|f| f.when(Array){|m| m} }
      rbuf[sbuf[0]..(sbuf[0]+sbuf[1..-1].size-1)]=sbuf[1..-1]
    }
    comm.each{ |s| @@visor.linked[s] << :ack }
    rbuf=rbuf.flatten
  end

  def mpi_bcast buf , comm 
    comm.each{ |s| @@visor.linked[s] << buf }
    comm.each{ Rubinius::Actor.receive{|f| f.when(:ack){|m| m} } }
  end

  def mpi_gather_tx sbuf , _rbuf , root , comm 
    rcomm=[root]
    rk=comm.find_index rank
    tbuf=[rk].concat sbuf
    mpi_bcast tbuf , rcomm
  end

  def mpi_gather_rx sbuf , rbuf , _root , comm 
    mpi_gather sbuf , rbuf , comm
  end

  # Gather from many to one.
  #
  # @param sbuf [Array] the send buffer.
  # @param rbuf [Array] the receiver buffer.
  # @param root [Fixnum] the node that receives all data.
  # @param comm [Array] the nodes that have data to send.
  # @return [Array] the receiver buffer with the gathered data.

  def gather sbuf , rbuf , root , comm
    rk=comm.find_index(rank)
    commderoot=comm.to_a-[root]
    mpi_gather_tx sbuf , rbuf , root , comm if commderoot.include? rank
    mpi_gather_rx sbuf , rbuf , root , commderoot if root==rank
    rbuf[rk..(rk+sbuf.size-1)]=sbuf if (comm.to_a & [root]).include? rank
    rbuf.flatten
  end

  def sendrecv sbuf , rbuf , root , comm
    root=root.to_a
    comm=comm.to_a
    mpi_gather_rx sbuf , rbuf , root , [ comm[root.find_index rank] ] if root.include? rank
    mpi_gather_tx sbuf , rbuf , root[ comm.find_index rank ] , [ rank ] if comm.include? rank
    rbuf
  end

  def mpi_bcast_tx sbuf , _rbuf , _root , comm
    tbuf=[0].concat sbuf
    mpi_bcast tbuf , comm 
  end

  def mpi_bcast_rx sbuf , rbuf , root , _comm
    mpi_gather sbuf , rbuf , [ root ]
  end

  # Broadcast  a copy of the send buffer +sbuf+ from +root+ to the receive buffer +rbuf+ of all nodes in the receiver array +comm+
  #
  # ==== Arguments 
  #
  # [sbuf] Send buffer Array.
  # [rbuf] Receive buffer Array.
  # [root] Sender rank Fixnum.
  # [comm] Receiver rank Array.
  #
  # ==== Returns
  #
  # [Array] 
  #
  # ==== Raises
  #
  # [MultiNodeError] If any node raises an exception
  #
  # ==== Example
  #
  # <code> 
  # # Broadcast sequence 0..7 individually from node 0 to nodes [0,1,2,3]
  #
  # p proc{8.times.map{|i| bcast [i] , [0] , 0 , 0..3}.flatten }*4 
  # </code>

  def bcast sbuf , rbuf , root , comm 
    commderoot=comm.to_a-[root]
    mpi_bcast_tx sbuf , rbuf , root , commderoot if root==rank
    mpi_bcast_rx sbuf , rbuf , root , commderoot if commderoot.include? rank
    rbuf=sbuf if (comm.to_a & [root]).include? rank
    rbuf
  end

  def mpi_scatter_tx sbuf , _rbuf , _root , comm 
    sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
      tbuf=[0].concat sb
      mpi_bcast tbuf , [cm]
    end
  end

  def mpi_scatter_rx sbuf , rbuf , root , _comm
    mpi_gather sbuf , rbuf , [ root ]
  end

  def scatter sbuf , rbuf , root , comm 
    mpi_scatter_tx sbuf , rbuf , root , comm if root == rank
    mpi_scatter_rx sbuf , rbuf , root , comm if comm.include? rank
    rbuf
  end

  def mpi_allgather_tx sbuf , _rbuf , root , comm 
    rnod=root.find_index rank
    tbuf=[rnod].concat sbuf
    mpi_bcast tbuf , comm
  end

  def mpi_allgather_rx sbuf , rbuf , root , _comm 
    mpi_gather sbuf , rbuf , root
  end

  def allgather sbuf , rbuf , root , comm 
    mpi_allgather_tx sbuf , rbuf , root , comm if root.include? rank
    mpi_allgather_rx sbuf , rbuf , root , comm if comm.include? rank
    rbuf
  end

  def mpi_alltoall_tx sbuf , _rbuf , root , comm 
    sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
      rnod=root.find_index rank
      tbuf=[rnod].concat sb
      mpi_bcast tbuf , [cm]
    end
  end

  def mpi_alltoall_rx sbuf , rbuf , root , _comm 
    mpi_gather sbuf , rbuf , root
  end

  def alltoall sbuf , rbuf , root , comm 
    mpi_alltoall_tx sbuf , rbuf , root , comm if root.include? rank
    mpi_alltoall_rx sbuf , rbuf , root , comm if comm.include? rank
    rbuf
  end

  class << self

    def start mproc, mult 
      init mult
      mult.times{ @@visor << Work[mproc] }
      finalize
    end

    def wait_size freshsize
        sleep 0.01 until @@visor.linked.size==freshsize
        sleep 0.1
    end

    def do_loop
      proc do |frank|
        current.rank=frank
        current.size=@@size
        work = Rubinius::Actor.receive
        sleep 0.1
        @@ret[frank]=current.instance_exec( &work.msg )
        @@visor << Ready[current]
        Rubinius::Actor.receive
      end
    end

    def do_filter dready , dwork, dstop
        proc do |f|
          f.when Work, &dwork 
          f.when Ready, &dready
          f.when Stop, &dstop
          f.when Actor::DeadActorError do |ex|
            unless ex.reason.nil?
              node = ex.actor
              warn "Node #{node.rank}/#{node.size} exit: #{ex.reason.inspect}"
              @@exc[ex.actor.rank]<<ex
            end
          end
        end 
    end
 
    def init_manager freshsize 
      @@size= freshsize
      @@nodes = []
      @@ret = [nil]*@@size
      @@exc = Array.new(@@size+1){[]}
      @@work_end = false
    end
       
    def init freshsize

      init_manager freshsize

      @@visor = spawn(@@size) do |fsize|

        Actor.trap_exit = true
        fsize.times{|i| spawn_link(i,&do_loop) }
        wait_size freshsize

        @@nodes = current.linked.dup

        do_ready =proc{ |who|
            @@nodes<<who.this
            @@nodes.each{ |rw| rw << Stop[:now] } if @@work_end and @@nodes.size==fsize }
        do_work  =proc{ |work| @@nodes.pop << work unless @@nodes.empty? }
        do_stop  =proc{ @@work_end = true }

        filter=do_filter do_ready , do_work, do_stop
        loop { Rubinius::Actor.receive(&filter) }

      end

      wait_size freshsize
    end

    def multinode 
      log = "Fresh raised #{@@exc.flatten.size} exceptions:\n"
      log += @@exc.flatten.map{|ex| 
        "Node #{ex.actor.rank}/#{ex.actor.size} exit: #{ex.reason.inspect}"
      }.join("\n")
      MultiNodeError.new(@@exc,log)
    end

    def finalize
      @@visor<<Stop[:now]
      wait_size 0
      raise multinode unless @@exc.flatten.empty?
      @@ret
    end

  end

end

class Proc
  def * mult
    Fresh.start self , mult
  end
end

class MultiNodeError < RuntimeError
  attr_reader :multi
  attr_reader :reason
  def initialize(multi, reason)
    super(reason)
    @multi = multi
    @reason = reason
  end
end

Ready = Struct.new(:this)
Work  = Struct.new(:msg)
Stop  = Struct.new(:stp)

