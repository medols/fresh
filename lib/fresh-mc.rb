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

class Array

  dot = self.instance_method(:*)

  define_method(:*) do |arg|
    if arg.is_a? Array
      self.zip(arg).reduce(0){ |t,v| t+v.reduce(:*) }
    else
      dot.bind(self).call(arg)
    end
  end

  def bcast *args
    Fresh::current.bcast(*([self].concat([*args])))
  end

  def gather *args
    Fresh::current.gather(*([self].concat([*args])))
  end

  def scatter *args
    Fresh::current.scatter(*([self].concat([*args])))
  end

  def allgather *args
    Fresh::current.allgather(*([self].concat([*args])))
  end

  def alltoall *args
    Fresh::current.alltoall(*([self].concat([*args])))
  end


end

class BaseFresh < Rubinius::Actor 

  attr_accessor :rank
  attr_accessor :size

  def root
    0
  end

  def all
    (0...size).to_a
  end

end

class Fresh < BaseFresh 

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
    commderoot = [*comm] - [*root]
    return unless commderoot.include? rank
    rcomm=[root]
    rk=comm.find_index rank
    tbuf=[rk*sbuf.size].concat sbuf
    mpi_bcast tbuf , rcomm
  end

  def mpi_gather_rx sbuf , rbuf , root , comm 
    return unless [*root].include? rank
    comm = [*comm] - [*root]
    mpi_gather sbuf , rbuf , comm
  end

  def mpi_gather_lc sbuf , rbuf , root , comm
    commandroot= [*comm] & [*root]
    return unless commandroot.include? rank
    rk=comm.find_index(rank)
    rbuf[rk..(rk+sbuf.size-1)]=[*sbuf] if commandroot.include? rank
  end

  def reduce_scatter op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    rbuf2=rbuf.dup unless rbuf.nil?
    res=reduce op, sbuf , rbuf , rt , comm ,  to:to , from:from
    scatter res , rbuf2 , rt , comm , to:to, from:from
  end

  def allgather sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= to
    rt   ||= root
    rt     = [*rt]
    comm ||= from
    comm ||= all
    comm   = [*comm]
    rbuf ||= [0]*(sbuf.size*comm.size)
    rbuf2||= [0]*(rbuf.size)
    res=gather sbuf , rbuf , rt.first , comm 
    bcast res , rbuf2 , rt.first , rt 
  end

  def scan op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= to
    rt   ||= root
    rt     = [*rt]
    comm ||= from
    comm ||= all
    comm   = [*comm]
    rbuf ||= [0]*(sbuf.size*comm.size)
    rbuf2||= [0]*(rbuf.size)
    res=gather sbuf , rbuf , rt.first , comm 
    res2=bcast res , rbuf2 , rt.first , rt
    if rt.index(rank).nil?
      [ * res2.reduce(op) ]
    else
      [ * res2.values_at(*rt.values_at(*0..(rt.index(rank)))).reduce(op) ]
    end
  end

  def allreduce op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= to
    rt   ||= root
    rt     = [*rt]
    comm ||= from
    comm ||= all
    comm   = [*comm]
    rbuf ||= [0]*(sbuf.size*comm.size)
    rbuf2||= [0]*(rbuf.size/rt.size)
    res=reduce op, sbuf , rbuf , rt.first , comm 
    bcast res , rbuf2 , rt.first , rt 
  end

  def reduce op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    res=gather( sbuf , rbuf , rt , comm ,  to:to , from:from )
    sbuf.size.times.map{|i|
      res.values_at(*(i...res.size).step(sbuf.size).to_a).reduce(op)
    }
  end

# Gather from many to one.
#
# @param sbuf [Array] the send buffer.
# @param rbuf [Array] the receiver buffer.
# @param root [Fixnum] the node that receives all data.
# @param comm [Array] the nodes that have data to send.
# @return [Array] the receiver buffer with the gathered data.

  def gather sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= to
    rt   ||= root
    comm ||= from
    comm ||= all
    rbuf ||= [0]*(sbuf.size*comm.size)
    base_gather sbuf , rbuf , rt , comm
  end

  def base_gather sbuf , rbuf , root , comm
    mpi_gather_tx sbuf , rbuf , root , comm
    mpi_gather_rx sbuf , rbuf , root , comm
    mpi_gather_lc sbuf , rbuf , root , comm 
    [*rbuf]
  end

  def sendrecv sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= to
    rt   ||= root
    comm ||= from
    comm ||= root
    rbuf ||= [0]*sbuf.size
    base_sendrecv sbuf , rbuf , rt , comm
  end

  def base_sendrecv sbuf , rbuf , root , comm
    root = [*root]
    comm = [*comm]
    commderoot = comm - root
    rootdecomm = root - comm
    mpi_gather_tx sbuf , rbuf , root [ comm.find_index rank ] , [ rank ] if commderoot.include? rank
    mpi_gather_rx sbuf , rbuf , root , [ comm[root.find_index rank] ] if rootdecomm.include? rank
    [*rbuf]
  end

  def mpi_bcast_tx sbuf , _rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless [*root].include? rank
    tbuf=[0].concat sbuf
    mpi_bcast tbuf , commderoot 
  end

  def mpi_bcast_rx sbuf , rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
    mpi_gather sbuf , rbuf , [ root ]
  end

  def mpi_bcast_lc sbuf , rbuf , root , comm
    commandroot=[*comm] & [*root]
    return unless commandroot.include? rank
    rbuf[0..-1]=[*sbuf]
  end

# Broadcast  a copy of the send buffer +sbuf+ from +root+ to the receive buffer +rbuf+ of all nodes in the receiver array +comm+
#
# @param sbuf [Array] the initialized sender buffer.
# @param rbuf [Array] the initialized receiver buffer.
# @param root [Fixnum] the sender rank.
# @param comm [Array] the set of receiver ranks. 
# @return [Array] the receiver buffer +rbuf+ with the incomming data
# @raise [MultiNodeError] If at least one node or the visor raises an exception
# @example Broadcast sequence 0..7 individually from node 0 to nodes [0,1,2,3]
# p proc{8.times.map{|i| bcast [i] , [0] , 0 , 0..3}.flatten }*4 
#

  def bcast sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= from
    rt   ||= root
    comm ||= to
    comm ||= all
    rbuf ||= [0]*sbuf.size
    base_bcast sbuf , rbuf , rt , comm
  end

  def base_bcast sbuf , rbuf , root , comm 
    mpi_bcast_tx sbuf , rbuf , root , comm
    mpi_bcast_rx sbuf , rbuf , root , comm
    mpi_bcast_lc sbuf , rbuf , root , comm 
    [*rbuf]
  end

  def mpi_scatter_tx sbuf , _rbuf , root , comm 
    return unless [*root].include? rank
    sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
      tbuf=[0].concat sb
      mpi_bcast tbuf , [cm] unless [*cm].include? rank
    end
  end

  def mpi_scatter_rx sbuf , rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
    mpi_gather sbuf , rbuf , [ root ]
  end

  def mpi_scatter_lc sbuf , rbuf , root , comm
    commandroot=[*comm] & [*root]
    return unless commandroot.include? rank
    sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
      rbuf[0..-1]=[*sb]  if [*cm].include? rank
    end
  end

  def scatter sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= from 
    rt   ||= root
    comm ||= to
    comm ||= all
    rbuf ||= [0]*(sbuf.size/comm.size)
    base_scatter sbuf , rbuf , rt , comm
  end

  def base_scatter sbuf , rbuf , root , comm 
    mpi_scatter_tx sbuf , rbuf , root , comm
    mpi_scatter_rx sbuf , rbuf , root , comm
    mpi_scatter_lc sbuf , rbuf , root , comm
    [*rbuf]
  end

  def mpi_allgather_tx sbuf , _rbuf , root , comm 
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
    rnod=comm.find_index rank
    tbuf=[rnod].concat sbuf
    mpi_bcast tbuf , root
  end

  def mpi_allgather_rx sbuf , rbuf , root , comm
    rootdecomm =[*root] - [*comm]
    return unless rootdecomm.include? rank
    mpi_gather sbuf , rbuf , comm
  end

  def allgather_old sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= to
    rt   ||= root
    comm ||= from
    comm ||= all
    rbuf ||= [0]*comm.size
    base_allgather sbuf , rbuf , rt , comm
  end

  def base_allgather sbuf , rbuf , root , comm 
    mpi_allgather_tx sbuf , rbuf , root , comm
    mpi_allgather_rx sbuf , rbuf , root , comm
    [*rbuf]
  end

  def mpi_alltoall_tx sbuf , _rbuf , root , comm 
    return unless comm.include? rank
    sbuf.each_slice(sbuf.size/root.size).zip(root) do |sb,cm|
      rnod=comm.find_index rank
      tbuf=[rnod].concat sb
      mpi_bcast tbuf , [cm]
    end
  end

  def mpi_alltoall_rx sbuf , rbuf , root , comm 
    return unless root.include? rank
    mpi_gather sbuf , rbuf , comm
  end

  def alltoall sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
    sbuf = [*sbuf]
    rt   ||= to
    rt   ||= root
    comm ||= from
    comm ||= all
    rbuf ||= [0]*comm.size
    base_alltoall sbuf , rbuf , rt , comm
  end

  def base_alltoall sbuf , rbuf , root , comm 
    mpi_alltoall_tx sbuf , rbuf , root , comm
    mpi_alltoall_rx sbuf , rbuf , root , comm
    rbuf
  end

  class << self

    @@size= 0
    @@nodes = []
    @@ret = []
    @@exc = []
    @@work_end = false
    @@visor = nil

    @@Do_work = proc{ |work| @@nodes.pop << work }

    @@Do_stop = proc{ @@work_end = true }

    @@Do_ready= 
      proc do |who|
        @@nodes<<who.this
        @@nodes.each{ |rw| rw << Stop[:now] } if @@work_end and @@nodes.size==@@size
      end

    @@Do_excp = 
      proc do |ex|
        unless ex.reason.nil?
          node = ex.actor
          warn "\nNode #{node.rank}/#{node.size} exit:\n#{ex.reason.backtrace.inspect}"
          @@exc[ex.actor.rank]<<ex
        end
      end

    @@Do_filter = 
      proc do |f|
        f.when Work , & @@Do_work 
        f.when Ready, & @@Do_ready
        f.when Stop , & @@Do_stop
        f.when Rubinius::Actor::DeadActorError, & @@Do_excp
      end 
 
    def do_loop
      proc do |rk|
        current.rank=rk
        current.size=@@size
        work = Rubinius::Actor.receive
        sleep 0.1
        @@ret[rk]=current.instance_exec( &work.msg )
        @@visor << Ready[current]
        Rubinius::Actor.receive
      end
    end

    def start mproc, mult 
      init mult
      mult.times{ @@visor << Work[mproc] }
      finalize
    end

    def wait_size freshsize
        sleep 0.01 until @@visor.linked.size==freshsize
        sleep 0.1
    end

    def init_manager freshsize 
      @@size= freshsize
      @@ret = [nil]*@@size
      @@exc = Array.new(@@size+1){[]}
    end

    def init freshsize
      init_manager freshsize
      @@visor = spawn do 
        Rubinius::Actor.trap_exit = true
        @@size.times{|i| spawn_link(i,&do_loop) }
        @@nodes.concat current.linked.dup
        loop { Rubinius::Actor.receive(&@@Do_filter) }
      end
      wait_size freshsize
    end

    def multinode 
      log = "Fresh raised #{@@exc.flatten.size} exceptions:\n"
      log += @@exc.flatten.map{|ex| 
        "Node #{ex.actor.rank}/#{ex.actor.size} exit: #{ex.reason.backtrace.inspect}"
      }.join("\n")
      MultiNodeError.new(@@exc,log)
    end

    def finalize
      @@visor<<Stop[:now]
      wait_size 0
      @@nodes=[]
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

