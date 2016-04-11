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
#    return self.zip(arg).reduce(0){ |t,v| t+v.reduce(:*) } if arg.is_a? Array
    return self.zip(arg).map{|a,b|a*b}.reduce(:+) if arg.is_a? Array
    dot.bind(self).call(arg)
  end

  def bcast *args
    Fresh::current.bcast(*([self].concat(args)))
  end

  def gather *args
    Fresh::current.gather(*([self].concat(args)))
  end

  def scatter *args
    Fresh::current.scatter(*([self].concat(args)))
  end

  def allgather *args
    Fresh::current.allgather(*([self].concat(args)))
  end

  def alltoall *args
    Fresh::current.alltoall(*([self].concat(args)))
  end

  def areduce *args
    Fresh::current.reduce(*([[*args][0],self].concat(args[1..-1])))
  end

  def scatterv *args
    Fresh::current.scatterv(*([[*args][0],[*args][1],self].concat(args[2..-1])))
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

  def linked
    @links
  end

#  def mpi_bcast sbuf , comm 
  def base_tx sbuf , comm 
    comm.each{ |s| @@visor.linked[s] << sbuf }
    comm.each{ Rubinius::Actor.receive{|f| f.when(:ack){|m| m} } }
  end

#  def mpi_gather _sbuf , rbuf, comm
  def base_rx rbuf, comm
    comm.each{
#      sbuf=Rubinius::Actor.receive{|f| f.when(Array){|m| m} }
#      rbuf[sbuf[0]..(sbuf[0]+sbuf[1..-1].size-1)]=sbuf[1..-1]
      tbuf=Rubinius::Actor.receive{|f| f.when(Array){|m| m} }
      rbuf[tbuf[0]..(tbuf[0]+tbuf[1..-1].size-1)]=tbuf[1..-1]
    }
    comm.each{ |s| @@visor.linked[s] << :ack }
    rbuf=rbuf.flatten
  end

  class << self

    @@size= 0
    @@nodes = []
    @@nodes_run = []
    @@ret = []
    @@exc = []
    @@work_end = false
    @@last_end = false
    @@visor = nil

    @@Do_work = proc{ |work| 
      @@nodes.pop << work 
      @@nodes_run.each{|n| n<<1} if @@nodes.empty? # synchronous start
    }

    @@Do_stop = proc{ @@work_end = true }

    @@Do_ready= 
      proc do |who|
        @@nodes<<who.this
        if @@work_end and @@nodes.size==@@size
          @@nodes.each{ |rw| rw << Stop[:now] }
          @@last_end=true
          @@main<<1 # synchronous end
        end
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
        Rubinius::Actor.receive
        #wait_size @@size 
        #sleep 0.1
        @@ret[rk]=current.instance_exec( &work.msg )
        @@visor << Ready[current]
        Rubinius::Actor.receive
      end
    end

    def start mproc, mult 
      init mult
      mult.times{ 
        @@visor << Work[mproc]
      }
      finalize
    end

    def wait_size size
      sleep 0.01 until @@visor.linked.size==size
      sleep 0.01
    end

    def init_manager freshsize 
      @@size= freshsize
      @@ret = [nil]*@@size
      @@exc = Array.new(@@size+1){[]}
    end

    def init freshsize
      init_manager freshsize
      @@main  = current
      #@@visor = spawn(current) do |main|
      @@visor = spawn do 
        Rubinius::Actor.trap_exit = true
        @@size.times{|i| spawn_link(i,&do_loop) }
        @@nodes.concat current.linked.dup
        @@nodes_run.concat current.linked.dup
        #main << Ready[current]
        @@main << Ready[current]
        Rubinius::Actor.receive(&@@Do_filter) until false
      end
      #wait_size freshsize
      Rubinius::Actor.receive
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
      Rubinius::Actor.receive
      #wait_size 0
      @@nodes=[]
      @@nodes_run=[]
      raise multinode unless @@exc.flatten.empty?
      @@ret
    end

  end

end

class Fresh < BaseFresh 

#  def bcast    sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#  def sendrecv sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#  def gather   sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#  def scatter  sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#  def reduce op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#  def scan op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#  def allgather sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#  def scatterv scon , sdis , sbuf , rbuf , rt , comm
#  def alltoall sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#  def allreduce op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil

  def argsapi *args
    call = caller[0][/`.*'/][1..-2]
    sbuf =[*args[0]]
    hash = Hash===args[-1] && args[-1]
    rt   = args[2] || 
           ( call[/bcast|scatter|scatterv/] && hash && hash[:from]) || 
           (!call[/bcast|scatter|scatterv/] && hash && hash[:to]) || 
           root
    comm = args[3] || 
           ( call[/bcast|scatter|scatterv/] && hash && hash[:to]) || 
           (!call[/bcast|scatter|scatterv/] && hash && hash[:from]) || 
           ( call[/sendrecv/] && root) || 
           all
    rbuf = ( !(Hash===args[1]) && args[1] ) || 
           [0]*( 
           (call[/alltoall/] && comm.size) || 
           (call[/sendrecv|bcast/] && sbuf.size) || 
           (call[/scatter|scatterv/] && (sbuf.size/comm.size)) || 
           (sbuf.size*comm.size) )
    #p([ sbuf , rbuf , rt , comm ])
    [ sbuf , rbuf , rt , comm ]
  end
 
#  def linked
#    @links
#  end

#  def mpi_gather sbuf , rbuf, comm
#    comm.each{
#      sbuf=Rubinius::Actor.receive{|f| f.when(Array){|m| m} }
#      rbuf[sbuf[0]..(sbuf[0]+sbuf[1..-1].size-1)]=sbuf[1..-1]
#    }
#    comm.each{ |s| @@visor.linked[s] << :ack }
#    rbuf=rbuf.flatten
#  end

#  def mpi_bcast buf , comm 
#    comm.each{ |s| @@visor.linked[s] << buf }
#    comm.each{ Rubinius::Actor.receive{|f| f.when(:ack){|m| m} } }
#  end

# Gather from many to one.
#
# @param sbuf [Array] the send buffer.
# @param rbuf [Array] the receiver buffer.
# @param root [Fixnum] the node that receives all data.
# @param comm [Array] the nodes that have data to send.
# @return [Array] the receiver buffer with the gathered data.

  def gather *args
    base_gather(*argsapi(*args))
  end

  def base_gather sbuf , rbuf , root , comm
    gather_tx sbuf , rbuf , root , comm
    gather_rx sbuf , rbuf , root , comm
    gather_lc sbuf , rbuf , root , comm 
    [*rbuf]
  end

  def gather_tx sbuf , _rbuf , root , comm 
    commderoot = [*comm] - [*root]
    return unless commderoot.include? rank
    rcomm=[root]
    rk=comm.find_index rank
    tbuf=[rk*sbuf.size].concat sbuf
#    mpi_bcast tbuf , rcomm
    base_tx tbuf , rcomm
  end

  def gather_rx sbuf , rbuf , root , comm 
    return unless [*root].include? rank
    comm = [*comm] - [*root]
#    mpi_gather sbuf , rbuf , comm
    base_rx rbuf , comm
  end

  def gather_lc sbuf , rbuf , root , comm
    commandroot= [*comm] & [*root]
    return unless commandroot.include? rank
    rk=comm.find_index(rank)
    rbuf[rk..(rk+sbuf.size-1)]=[*sbuf] if commandroot.include? rank
  end

  def scan *args
    base_scan(args[0],*argsapi(*args[1..-1]))
  end

  def base_scan op, sbuf , rbuf , rt , comm
    rt     = [*rt]
    comm   = [*comm]
    rbuf2  = [0]*(rbuf.size)
    res=gather sbuf , rbuf , rt.first , comm 
    res2=bcast res , rbuf2 , rt.first , rt
    if rt.index(rank).nil?
      [ * res2.reduce(op) ]
    else
      [ * res2.values_at(*rt.values_at(*0..(rt.index(rank)))).reduce(op) ]
    end
  end

  def allgather *args
    base_allgather(*argsapi(*args))
  end

  def base_allgather sbuf , rbuf , rt , comm 
    rt     = [*rt]
    comm   = [*comm]
    rbuf2  = [0]*(rbuf.size)
    res=gather sbuf , rbuf , rt.first , comm 
    bcast res , rbuf2 , rt.first , rt 
  end

  def reduce *args
    base_reduce(args[0],*argsapi(*args[1..-1]))
  end

  def base_reduce op, sbuf , rbuf , rt , comm
    res=gather sbuf , rbuf , rt , comm
    sbuf.size.times.map{|i|
      res.values_at(*(i...res.size).step(sbuf.size).to_a).reduce(op)
    }
  end

  def reduce_scatter *args
    base_reduce_scatter(args[0],*argsapi(*args[1..-1]))
  end

  def base_reduce_scatter op, sbuf , rbuf , rt , comm
    rbuf2=rbuf.dup unless rbuf.nil?
    res=reduce op, sbuf , rbuf , rt , comm 
    scatter res , rbuf2 , rt , comm 
  end

  def allreduce *args 
    base_allreduce(args[0],*argsapi(*args[1..-1]))
  end

  def base_allreduce op, sbuf , rbuf , rt , comm
#    sbuf = [*sbuf]
#    rt   ||= to
#    rt   ||= root
#    rt     = [*rt]
#    comm ||= from
#    comm ||= all
#    comm   = [*comm]
#    rbuf ||= [0]*(sbuf.size*comm.size)
#    rbuf2||= [0]*(rbuf.size/rt.size)

    rt     = [*rt]
    comm   = [*comm]
    rbuf2  = [0]*(rbuf.size/rt.size)

    res=reduce op, sbuf , rbuf , rt.first , comm 
    bcast res , rbuf2 , rt.first , rt 
  end

#  def allreduce op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#    sbuf = [*sbuf]
#    rt   ||= to
#    rt   ||= root
#    rt     = [*rt]
#    comm ||= from
#    comm ||= all
#    comm   = [*comm]
#    rbuf ||= [0]*(sbuf.size*comm.size)
#    rbuf2||= [0]*(rbuf.size/rt.size)
#    res=reduce op, sbuf , rbuf , rt.first , comm 
#    bcast res , rbuf2 , rt.first , rt 
#  end

#  def reduce_scatter op, sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#    rbuf2=rbuf.dup unless rbuf.nil?
#    res=reduce op, sbuf , rbuf , rt , comm ,  to:to , from:from
#    scatter res , rbuf2 , rt , comm , to:to, from:from
#  end

  def sendrecv *args
    base_sendrecv(*argsapi(*args))
  end
 
  def base_sendrecv sbuf , rbuf , root , comm
    root = [*root]
    comm = [*comm]
    commderoot = comm - root
    rootdecomm = root - comm
    gather_tx sbuf , rbuf , root [ comm.find_index rank ] , [ rank ] if commderoot.include? rank
    gather_rx sbuf , rbuf , root , [ comm[root.find_index rank] ] if rootdecomm.include? rank
    [*rbuf]
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

#  def bcast sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil

  def bcast *args
    base_bcast(*argsapi(*args))
  end

  def base_bcast sbuf , rbuf , root , comm 
    bcast_tx sbuf , rbuf , root , comm
    bcast_rx sbuf , rbuf , root , comm
    bcast_lc sbuf , rbuf , root , comm 
    [*rbuf]
  end

  def bcast_tx sbuf , _rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless [*root].include? rank
    tbuf=[0].concat sbuf
#    mpi_bcast tbuf , commderoot 
    base_tx tbuf , commderoot 
  end

  def bcast_rx sbuf , rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
#    mpi_gather sbuf , rbuf , [ root ]
    base_rx rbuf , [ root ]
  end

  def bcast_lc sbuf , rbuf , root , comm
    commandroot=[*comm] & [*root]
    return unless commandroot.include? rank
    rbuf[0..-1]=[*sbuf]
  end

  def each_slice sbuf, spos, slen
    #spos.zip(slen).map{|p,l| sbuf.new_rangex(p,l).map{|m|m||0}}
    spos.zip(slen).map{|p,l| sbuf.new_range(p,l).map{|m|m||0}}
  end

  def scatterv *args
    base_scatterv(args[0],args[1],*argsapi(*args[2..-1]))
  end

  def base_scatterv scon , sdis , sbuf , rbuf , root , comm
    rbuf=[0]*scon[rank] 
    scatterv_tx scon , sdis , sbuf , root , comm
    scatterv_rx sbuf , rbuf , root , comm
    scatterv_lc scon , sdis , sbuf , rbuf , root , comm
    [*rbuf]
  end

  def scatterv_tx scon , sdis , sbuf , root , comm 
    return unless [*root].include? rank
    each_slice(sbuf,sdis,scon).zip(comm) do |sb,cm|
      tbuf=[0].concat sb
#      mpi_bcast tbuf , [cm] unless [*cm].include? rank
      base_tx tbuf , [cm] unless [*cm].include? rank
    end
  end

  def scatterv_rx sbuf , rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
#    mpi_gather sbuf , rbuf , [ root ]
    base_rx rbuf , [ root ]
  end

  def scatterv_lc scon , sdis , sbuf , rbuf , root , comm
    commandroot=[*comm] & [*root]
    return unless commandroot.include? rank
    each_slice(sbuf,sdis,scon).zip(comm) do |sb,cm|
      rbuf[0..-1]=[*sb]  if [*cm].include? rank
    end
  end

  def scatter *args
    base_scatter(*argsapi(*args))
  end

  def base_scatter sbuf , rbuf , root , comm 
    scatter_tx sbuf , rbuf , root , comm
    scatter_rx sbuf , rbuf , root , comm
    scatter_lc sbuf , rbuf , root , comm
    [*rbuf]
  end

  def scatter_tx sbuf , _rbuf , root , comm 
    return unless [*root].include? rank
    sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
      tbuf=[0].concat sb
#      mpi_bcast tbuf , [cm] unless [*cm].include? rank
      base_tx tbuf , [cm] unless [*cm].include? rank
    end
  end

  def scatter_rx sbuf , rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
#    mpi_gather sbuf , rbuf , [ root ]
    base_rx rbuf , [ root ]
  end

  def scatter_lc sbuf , rbuf , root , comm
    commandroot=[*comm] & [*root]
    return unless commandroot.include? rank
    sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
      rbuf[0..-1]=[*sb]  if [*cm].include? rank
    end
  end

#  def alltoall sbuf , rbuf=nil , rt=nil , comm=nil ,  to:nil , from:nil
#    sbuf = [*sbuf]
#    rt   ||= to
#    rt   ||= root
#    comm ||= from
#    comm ||= all
#    rbuf ||= [0]*comm.size
#    base_alltoall sbuf , rbuf , rt , comm
#  end

  def alltoall *args
    base_alltoall(*argsapi(*args))
  end

  def base_alltoall sbuf , rbuf , root , comm 
    alltoall_tx sbuf , rbuf , root , comm
    alltoall_rx sbuf , rbuf , root , comm
    rbuf
  end

  def alltoall_tx sbuf , _rbuf , root , comm 
    return unless comm.include? rank
    sbuf.each_slice(sbuf.size/root.size).zip(root) do |sb,cm|
      rnod=comm.find_index rank
      tbuf=[rnod].concat sb
#      mpi_bcast tbuf , [cm]
      base_tx tbuf , [cm]
    end
  end

  def alltoall_rx sbuf , rbuf , root , comm 
    return unless root.include? rank
#    mpi_gather sbuf , rbuf , comm
    base_rx rbuf , comm
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

