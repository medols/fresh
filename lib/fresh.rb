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

def mpi_init id, all
	$node ||= all.times.map{false}
	symid = ("n"+id.to_s).to_sym
	$node[id] = Rubinius::Actor[symid] = Rubinius::Actor.current
	sleep 0.1 until $node.all? 
end

def mpi_end id, all
	$node[id]=false
end

def mpi_gather_recv grp , inv, chc
        grp.each{ |s|
                res=Rubinius::Actor.receive{|f| f.when(Array){|m| m} }
                inv[res[0]..(res[0]+res[1..-1].size-1)]=res[1..-1]
        }
        grp.each{ |s| $node[s] << :ack }
        inv=inv.flatten
end

def mpi_gather_send grp , msg
        grp.each{ |s|
                $node[s] << msg
        }
        grp.each{ |s|
                res=Rubinius::Actor.receive{|f| f.when(:ack){|m| m} }
        }
end

def fresh m
	$main=m
	$main.size.times{ |i|
        	Rubinius::Actor.spawn(i){ |id|
			Rubinius::Actor.trap_exit = true
        	        mpi_init id, $main.size
        	        $main[id].call id, $main.size
			mpi_end id, $main.size
        	}
	}
	sleep 0.1 until $node.none?
end

