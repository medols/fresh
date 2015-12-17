# fresh.rb - Fresh gem for multi-core processing. 
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
	$node ||= size.times.map{false}
	symid = ("n"+rank.to_s).to_sym
	$node[rank] = Rubinius::Actor[symid] = Rubinius::Actor.current
	sleep 0.1 until $node.all? 
end

def mpi_end rank, _size
	$node[rank]=false
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
        comm.each{ |s|
                $node[s] << buf
        }
        comm.each{
                Rubinius::Actor.receive{|f| f.when(:ack){|m| m} }
        }
end

def fresh *m
	$stdout.sync = true
	$main=m.flatten
	$return=[]
	$main.size.times{ |i|
        	Rubinius::Actor.spawn(i){ |rank|
			Rubinius::Actor.trap_exit = true
        	        mpi_init rank, $main.size
        	        $return[rank]=$main[rank].call rank, $main.size
			mpi_end rank, $main.size
        	}
	}
	sleep 0.1 until $node.none?
	$return
end

