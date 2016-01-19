# fresh-mc.rb - Fresh gem for multi-core processing. 
#
# Copyright 2015  Jaume Masip-Torne <jmasip@gianduia.net>
#           2015  Ismael Merodio-Codinachs <ismael@gianduia.net>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   thi slist of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice
#   this list of conditions and the following disclaimer in the documentatio
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

require "rubinius/actor"

def mpi_init rank, size
	symid = ("n"+rank.to_s).to_sym
	$node[rank] = Rubinius::Actor[symid] = Rubinius::Actor.current
	sleep 0.05 until $node.all? 
	sleep 0.1
end

def mpi_finalize rank, _size
	$node[rank]=false
end

def proc_mult pr_size , pr_one
	pa=[ proc{ |rk,sz| pr_one } ] * pr_size
	pa.each_with_index.map{|f,rk| f.call(rk,pr_size)}
end

def fresh *m
	main=m.flatten
        msize=main.size
	$node = [false]*msize
	mpi_ret = [false]*msize
	main.each_with_index{ |mpi_proc,index|
        	Rubinius::Actor.spawn(index,msize){ |rank,size|
        	        mpi_init rank, size
        	        mpi_ret[rank]=mpi_proc.call rank, size
			mpi_finalize rank, size
        	}
	}
	sleep 0.05 until $node.none?
	sleep 0.1
	mpi_ret
end

class Proc
  def * mult
    fresh( proc_mult( mult , self ) )
  end
end

def mpi_gather sbuf , rbuf, comm
        comm.each{
                sbuf=Rubinius::Actor.receive{|f| f.when(Array){|m| m} }
                rbuf[sbuf[0]..(sbuf[0]+sbuf[1..-1].size-1)]=sbuf[1..-1]
        }
        comm.each{ |s| $node[s] << :ack }
        rbuf=rbuf.flatten
end

def mpi_bcast buf , comm 
        comm.each{ |s| $node[s] << buf }
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
  mpi_gather_rx sbuf , rbuf , root , comm , rr  if rr==root
  mpi_gather_tx sbuf , rbuf , root , comm , rr  if comm.include? rr
  rbuf
end

def mpi_sendrecv sbuf , rbuf , root , comm , rr
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
  mpi_bcast_tx sbuf , rbuf , root , comm , rr  if rr==root
  mpi_bcast_rx sbuf , rbuf , root , comm , rr  if comm.include? rr
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

