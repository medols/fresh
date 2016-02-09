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
# * Neither the name of the Evan Phoenix nor the names of its contributors
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

class Proc
  def * mult
    Fresh.start mult , self 
  end
end

def mpi_gather sbuf , rbuf, comm
  comm.each{
    sbuf=Rubinius::Actor.receive{|f| f.when(Array){|m| m} }
    rbuf[sbuf[0]..(sbuf[0]+sbuf[1..-1].size-1)]=sbuf[1..-1]
  }
  comm.each{ |s| Fresh[s] << :ack }
  rbuf=rbuf.flatten
end

def mpi_bcast buf , comm 
  comm.each{ |s| Fresh[s] << buf }
  comm.each{
    Rubinius::Actor.receive{|f| f.when(:ack){|m| m} }
  }
end

def mpi_gather_tx sbuf , _rbuf , root , comm , rr
  rcomm=[root]
  rk=comm.find_index(rr)
  tbuf=[rk].concat sbuf
  mpi_bcast tbuf , rcomm
end

def mpi_gather_rx sbuf , rbuf , _root , comm , _rr
  mpi_gather sbuf , rbuf , comm
end

def mpi_gatherv sbuf , rbuf , root , comm , rr
  rk=comm.find_index(rr)
  commderoot=comm.to_a-[root]
  mpi_gather_tx sbuf , rbuf , root , comm , rr  if commderoot.include? rr
  mpi_gather_rx sbuf , rbuf , root , commderoot , rr  if root==rr
  rbuf[rk..(rk+sbuf.size-1)]=sbuf if (comm.to_a & [root]).include?(rr)
  rbuf.flatten
end

def mpi_sendrecv sbuf , rbuf , root , comm , rr
  root=root.to_a
  comm=comm.to_a
  mpi_gather_rx sbuf , rbuf , root , [ comm[root.find_index(rr)] ] , rr  if root.include? rr
  mpi_gather_tx sbuf , rbuf , root[ comm.find_index(rr) ] , [ rr ] , rr  if comm.include? rr
  rbuf
end

def mpi_bcast_tx sbuf , _rbuf , _root , comm , _rr
  tbuf=[0].concat sbuf
  mpi_bcast tbuf , comm 
end

def mpi_bcast_rx sbuf , rbuf , root , _comm , _rr
  mpi_gather sbuf , rbuf , [ root ]
end

def mpi_bcastv sbuf , rbuf , root , comm , rr
  commderoot=comm.to_a-[root]
  mpi_bcast_tx sbuf , rbuf , root , commderoot , rr  if root==rr
  mpi_bcast_rx sbuf , rbuf , root , commderoot , rr  if commderoot.include? rr
  rbuf=sbuf if (comm.to_a & [root]).include?(rr)
  rbuf
end

def mpi_scatter_tx sbuf , _rbuf , _root , comm , _rr
  sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
    tbuf=[0].concat sb
    mpi_bcast tbuf , [cm]
  end
end

def mpi_scatter_rx sbuf , rbuf , root , _comm , _rr
  mpi_gather sbuf , rbuf , [ root ]
end

def mpi_scatterv sbuf , rbuf , root , comm , rr
  mpi_scatter_tx sbuf , rbuf , root , comm , rr  if rr==root
  mpi_scatter_rx sbuf , rbuf , root , comm , rr  if comm.include? rr
  rbuf
end

def mpi_allgather_tx sbuf , _rbuf , root , comm , rr
  rnod=root.find_index(rr)
  tbuf=[rnod].concat sbuf
  mpi_bcast tbuf , comm
end

def mpi_allgather_rx sbuf , rbuf , root , _comm , _rr
  mpi_gather sbuf , rbuf , root
end

def mpi_allgatherv sbuf , rbuf , root , comm , rr
  mpi_allgather_tx sbuf , rbuf , root , comm , rr  if root.include? rr
  mpi_allgather_rx sbuf , rbuf , root , comm , rr  if comm.include? rr
  rbuf
end

def mpi_alltoall_tx sbuf , _rbuf , root , comm , rr
  sbuf.each_slice(sbuf.size/comm.size).zip(comm) do |sb,cm|
    rnod=root.find_index(rr)
    tbuf=[rnod].concat sb
    mpi_bcast tbuf , [cm]
  end
end

def mpi_alltoall_rx sbuf , rbuf , root , _comm , _rr
  mpi_gather sbuf , rbuf , root
end

def mpi_alltoallv sbuf , rbuf , root , comm , rr
  mpi_alltoall_tx sbuf , rbuf , root , comm , rr  if root.include? rr
  mpi_alltoall_rx sbuf , rbuf , root , comm , rr  if comm.include? rr
  rbuf
end

require 'rubinius/actor'

module Rubinius
  class Actor
    attr_accessor :rank
    attr_accessor :size

    def linked
      @links
    end
    def bcast sbuf , rbuf , root , comm
      mpi_bcastv sbuf , rbuf , root , comm , rank
    end
    def gather sbuf , rbuf , root , comm
      mpi_gatherv sbuf , rbuf , root , comm , rank
    end
    def sendrecv sbuf , rbuf , root , comm
      mpi_sendrecv sbuf , rbuf , root , comm , rank
    end
    def scatter sbuf , rbuf , root , comm
      mpi_scatterv sbuf , rbuf , root , comm , rank
    end
    def allgather sbuf , rbuf , root , comm
      mpi_allgatherv sbuf , rbuf , root , comm , rank
    end
    def alltoall sbuf , rbuf , root , comm
      mpi_alltoallv sbuf , rbuf , root , comm , rank
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

class Fresh 

  class << self

    def start mproc, mult 
      init mult
      mult.times{ visor << Work[mproc] }
      finalize
    end

    def [] i
      visor.linked[i]
    end
 
    def []= i,ret
      @@ret[i]=ret
    end
 
    def visor
      @@visor
    end

    def exception i,e
      @@exc[i]<<e
    end

    def nodes
      @@nodes
    end

    def work_end
      @@work_end
    end

    def set_end
      @@work_end=true
    end

    def init_manager freshsize 
      @@size= freshsize
      @@nodes = []
      @@ret = [nil]*@@size
      @@exc = Array.new(@@size+1){[]}
      @@work_end = false
      @@work_loop = proc do |rank,size|
        Rubinius::Actor.current.rank=rank
        Rubinius::Actor.current.size=size
        loop do
          work = Rubinius::Actor.receive
          break if work.is_a? Stop
          sleep 0.1
          Fresh[rank]=Rubinius::Actor.current.instance_exec( &work.msg )
          Fresh.visor << Ready[Rubinius::Actor.current]
        end
      end
    end

    def init freshsize

      init_manager freshsize
      @@visor = Rubinius::Actor.spawn(@@size) do |fsize|

        Rubinius::Actor.trap_exit = true

        fsize.times do
          nodes << Rubinius::Actor.spawn_link(Rubinius::Actor.current.linked.size,fsize,&@@work_loop)
        end

      loop do
        Rubinius::Actor.receive do |f|
          f.when(Ready) do |who|
            nodes<<who.this
            nodes.each{ |rw| rw << Stop[:now] } if work_end and nodes.size==fsize
          end
          f.when(Work) do |work|
             nodes.pop << work unless nodes.empty? 
          end
          f.when(Stop) do
            set_end
          end
          f.when(Rubinius::Actor::DeadActorError) do |exit|
            unless exit.reason.nil?
              node = exit.actor
              warn "Node #{node.rank}/#{node.size} exit: #{exit.reason.inspect}"
              exception node.rank, exit
            end
          end
        end
     end

      end

      sleep 0.05 until visor.linked.size==freshsize
      sleep 0.1
    end

    def finalize
      visor<<Stop[:now]
      sleep 0.05 until visor.linked.empty?
      raise MultiNodeError.new(@@exc,"Fresh finished with #{@@exc.flatten.size} exceptions.") unless @@exc.flatten.empty?
      @@ret
    end

  end

end

