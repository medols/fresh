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

#p $:.grep /rubinius/
require 'rubinius/actor'

include Math

module Enumerable
  def sum
    inject(0, :+)
  end
  def dot sym,val
    return zip(val).map{|x,y| x.send(sym,y)} if Enumerable===val
    map{|e| e.send(sym,val) }
  end
#  def call *args, &block
#    return yield(*args) if self===Fresh::current.rank
#  end
end

#class Fixnum
#  def call *args, &block
#    return yield(*args) if self===Fresh::current.rank
#  end
#end

class Object
  def at range
    return yield if range===Fresh::current.rank
  end
end

class Array

  dot = self.instance_method(:*)

  define_method(:*) do |arg|
    return self.zip(arg).map{|a,b|a*b}.inject(:+) if Array===arg
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

  def size
    @@size
  end

  def root
    0
  end

  def all
    (0...size).to_a
  end

  def linked
    @links
  end

  def base_tx sbuf , comm 
    comm.each{ |s| @@visorlinked[s] << sbuf }
    comm.each{ Rubinius::Actor.receive{|f| f.when(:ack){|m| m} } }
  end

  def base_rx rbuf, comm
    comm.each{
      tbuf=Rubinius::Actor.receive{|f| f.when(Array){|m| m} }
      rbuf[tbuf[0]..(tbuf[0]+tbuf[1..-1].size-1)]=tbuf[1..-1]
    }
    comm.each{ |s| @@visorlinked[s] << :ack }
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

    def multinode 
      log = "Fresh raised #{@@exc.flatten.size} exceptions:\n"
      log += @@exc.flatten.map{|ex| 
        "Node #{ex.actor.rank}/#{ex.actor.size} exit: "+((ex.reason.nil?)?"OK":"#{ex.reason.backtrace.inspect}")
      }.join("\n")
      MultiNodeError.new(@@exc,log)
    end

    def dev mult, &block
      @@size=mult
      @@mproc=block
      @@visor=current 
    end

    def calldev(*mult) 
      @@ret = [nil]*@@size
      @@exc = Array.new(@@size){[]}
      @@params=mult

      Rubinius::Actor.trap_exit = true
      @@size.times do
        spawn_link do  
          current.rank=Rubinius::Actor.receive{|f| f.when(Rank){|m| m.rnk} }
          @@ret[current.rank]=current.instance_exec( *@@params , &@@mproc.dup ) 
        end
      end
      @@visorlinked=@@visor.linked.dup
      @@visorlinked.each_with_index{|l,i| l<<Rank[i]}
      while @@exc.any?{|e|e.empty?} do 
        ex = Rubinius::Actor.receive
        @@exc[ex.actor.rank] << ex unless @@exc[ex.actor.rank].nil?
      end
      raise multinode unless @@exc.flatten.all?{|e| e.reason.nil? }
      @@ret

    end

    def start mproc, *mult
      dev mult.shift, &mproc
      calldev(*mult)
    end

  end

end

def fed *args, &block
  block*args
end

def def_fdev mult, &block
  Fresh.dev mult, &block
end

def fdev_call *args
  Fresh.calldev(*args)
end

class Proc
  def *(*mult)
    Fresh.start(*([self].concat(mult).flatten))
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

#Ready = Struct.new(:this)
#Work  = Struct.new(:msg)
#Stop  = Struct.new(:stp)
Rank  = Struct.new(:rnk)

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

# def argsapi call, *args
#   call = caller[0][/`.*'/][1..-2]

# Gather from many to one.
#
# @param sbuf [Array] the send buffer.
# @param rbuf [Array] the receiver buffer.
# @param root [Fixnum] the node that receives all data.
# @param comm [Array] the nodes that have data to send.
# @return [Array] the receiver buffer with the gathered data.

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

class Fresh < BaseFresh 

  def argsapi call , *args
    sbuf =[*args[0]]
    hash = Hash===args[-1] && args[-1]
    rt   = args[2] ||
           ( call[/bcast|scatter|scatterv/] && hash && hash[:from]) || 
           (!call[/bcast|scatter|scatterv/] && hash && hash[:to]) || 
           ( call[/allgather/] && all) || 
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
           (sbuf.size*[*comm].size) )
    [ sbuf , rbuf , rt , comm ]
  end
 
  def gather *args
    base_gather(*argsapi("gather",*args))
  end

  def base_gather sbuf , rbuf , root , comm
    rt=[*root].first
    gather_tx sbuf , rbuf , rt , comm
    gather_rx sbuf , rbuf , rt , comm
    gather_lc sbuf , rbuf , rt , comm 
    [*rbuf]
  end

  def gather_tx sbuf , _rbuf , root , comm 
    commderoot = [*comm] - [*root]
    return unless commderoot.include? rank
    rcomm=[root]
    rk=comm.find_index rank
    tbuf=[rk*sbuf.size].concat sbuf
    base_tx tbuf , rcomm
  end

  def gather_rx _sbuf , rbuf , root , comm 
    return unless [*root].include? rank
    comm = [*comm] - [*root]
    base_rx rbuf , comm
  end

  def gather_lc sbuf , rbuf , root , comm
    commandroot= [*comm] & [*root]
    return unless commandroot.include? rank
    rk=comm.find_index(rank)
    rbuf[(rk*sbuf.size)..((rk+1)*sbuf.size-1)]=[*sbuf] if commandroot.include? rank
  end

  def scan *args
    base_scan(args[0],*argsapi("scan",*args[1..-1]))
  end

  def base_scan op, sbuf , rbuf , rt , comm
    rt     = [*rt]
    comm   = [*comm]
    rbuf2  = [0]*(rbuf.size)
    res=gather sbuf , rbuf , rt.first , comm 
    res2=bcast res , rbuf2 , rt.first , rt
    if rt.index(rank).nil?
      [ * res2.inject(op) ]
    else
      [ * res2.values_at(*rt.values_at(*0..(rt.index(rank)))).inject(op) ]
    end
  end

  def allgather *args
    base_allgather(*argsapi("allgather",*args))
  end

  def base_allgather sbuf , rbuf , rt , comm 
    rt     = [*rt]
    comm   = [*comm]
    rbuf2  = [0]*(rbuf.size)
    res=gather sbuf , rbuf , rt.first , comm 
    bcast res , rbuf2 , rt.first , rt 
  end

  def reduce *args
    base_reduce(args[0],*argsapi("reduce",*args[1..-1]))
  end

  def base_reduce op, sbuf , rbuf , rt , comm
    res=gather sbuf , rbuf , rt , comm
    sbuf.size.times.map{|i|
      res.values_at(*(i...res.size).step(sbuf.size).to_a).inject(op)
    }
  end

  def reduce_scatter *args
    base_reduce_scatter(args[0],*argsapi("reduce_scatter",*args[1..-1]))
  end

  def base_reduce_scatter op, sbuf , rbuf , rt , comm
    comm=[*comm]
    rbuf2=rbuf.dup unless rbuf.nil?
    res=reduce op, sbuf , rbuf , rt , comm 
    scatter res , rbuf2 , rt , comm 
  end

  def allreduce *args 
    base_allreduce(args[0],*argsapi("allreduce",*args[1..-1]))
  end

  def base_allreduce op, sbuf , rbuf , rt , comm
    rt     = [*rt]
    comm   = [*comm]
    rbuf2  = [0]*(rbuf.size/rt.size)

    res=reduce op, sbuf , rbuf , rt.first , comm 
    bcast res , rbuf2 , rt.first , rt 
  end

  def sendrecv *args
    base_sendrecv(*argsapi("sendrecv",*args))
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

  def bcast *args
    base_bcast(*argsapi("bcast",*args))
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
    base_tx tbuf , commderoot 
  end

  def bcast_rx _sbuf , rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
    base_rx rbuf , [ root ]
  end

  def bcast_lc sbuf , rbuf , root , comm
    commandroot=[*comm] & [*root]
    return unless commandroot.include? rank
    rbuf[0..-1]=[*sbuf]
  end

  def each_slice sbuf, spos, slen
    spos.zip(slen).map{|p,l| ss=sbuf.slice(p,l); ss.fill(0, l-1, l-ss.size)}
  end

  def scatterv *args
    base_scatterv(args[0],args[1],*argsapi("scatterv",*args[2..-1]))
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
      base_tx tbuf , [cm] unless [*cm].include? rank
    end
  end

  def scatterv_rx _sbuf , rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
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
    base_scatter(*argsapi("scatter",*args))
  end

  def base_scatter sbuf , rbuf , root , comm
    comm=[*comm] 
    scatter_tx sbuf , rbuf , root , comm
    scatter_rx sbuf , rbuf , root , comm
    scatter_lc sbuf , rbuf , root , comm
    [*rbuf]
  end

  def scatter_tx sbuf , _rbuf , root , comm 
    return unless [*root].include? rank
    sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
      tbuf=[0].concat sb
      base_tx tbuf , [cm] unless [*cm].include? rank
    end
  end

  def scatter_rx _sbuf , rbuf , root , comm
    commderoot =[*comm] - [*root]
    return unless commderoot.include? rank
    base_rx rbuf , [ root ]
  end

  def scatter_lc sbuf , rbuf , root , comm
    commandroot=[*comm] & [*root]
    return unless commandroot.include? rank
    sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
      rbuf[0..-1]=[*sb]  if [*cm].include? rank
    end
  end

  def alltoall *args
    base_alltoall(*argsapi("alltoall",*args))
  end

  def base_alltoall sbuf , rbuf , root , comm
    root=[*root] 
    alltoall_tx sbuf , rbuf , root , comm
    alltoall_rx sbuf , rbuf , root , comm
    rbuf
  end

  def alltoall_tx sbuf , _rbuf , root , comm 
    return unless comm.include? rank
    sbuf.each_slice(sbuf.size/root.size).zip(root) do |sb,cm|
      rnod=comm.find_index rank
      tbuf=[rnod].concat sb
      base_tx tbuf , [cm]
    end
  end

  def alltoall_rx _sbuf , rbuf , root , comm 
    return unless root.include? rank
    base_rx rbuf , comm
  end

end

