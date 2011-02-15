#!/usr/bin/ruby -Ku
#coding:utf-8

# 「ちょっと草植えときますね型言語 Grass」のRuby版インタプリタのモロパクリです。
# Grass設計者であるUENO Katsuhiro様に最上級の感謝を。

# 1時間でGrass覚えて、１時間ちょっとでソース読んで、１時間半正規表現と格闘して出来てしまっただけのものなので、バグが残ってるかも。
# 動作にはRubyが必要です。UbuntuとかMac使ってる方は「端末エミュレーター」なり「ターミナル」なりから動かせると思います。是非トライをば。

# サンプル（サンプル作るのに１時間余計にかかったのは内緒だ！）
# モグゴニョモグモグマミマミモグマミマミマミモグゴニョマミモグモグモグモグマミマミモグ	マミマミマミモグマミマミマミマミモグマミマミマミマミマミモグマミマミマミマミマミマミモグマミマミマミマミマミマミマミモグマミマミマミマミマミマミマミマミマミモグモグモグモグモグモグモグモグモグモグモグモグマミマミマミマミマミマミマミマミモグマミマミマミモグモグマミマミマミマミマミモグマミマミマミマミマミマミマミモグマミマミマミマミマミマミマミマミマミモグマミマミマミマミマミマミマミマミマミマミマミモグマミマミマミマミマミマミマミマミマミマミマミマミマミマミモグマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミモグモグモグモグモグモグモグモグマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミモグモグモグモグモグモグモグモグマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミモグモグモグマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミモグモグモグマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミモグモグモグマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミマミモグモグモグ

# 以下、オリジナルであるgrassのコピーライトを記しておきます
# 
## grass.rb - Grass interpreter
# http://www.blue.sky.or.jp/grass/
#
# Copyright (C) 2006, 2007 UENO Katsuhiro. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# History:
#
# 2007-10-02
#   - Follow the latest changes of the definition of Grass.
# 2007-09-20
#   - First version.
#

require "pp"

class Charlotte
	
	RELEASE_DATE = '2011-02-16'
	
	class Error < StandardError; end
	class RuntimeError < Error; end
	class IllegalState < Error; end
	
	Machine = Struct.new :code, :env, :dump
	
	class Value
		def char_code
			raise RuntimeError, "this is not a char"
		end
		
		def app m, arg
			raise RuntimeError, "method 'app' is undefined"
		end
	end
	
	class Insn
	end
	
	class App < Insn
		def initialize m, n
			@m, @n = m, n
		end
		
		def eval m
			f, v = m.env[-@m], m.env[-@n]
			raise "out of bound" unless f and v
			f.app m, v
		end
		
		def pretty_print q
			q.text "App"
			q.group(4, "(", ")") {
				q.seplist([@m, @n]) {|i|
					q.text "#{i}"
				}
			}
		end
		alias inspect pretty_print_inspect
	end
	
	class Abs < Insn
		def initialize body
			@body = body
		end
		
		def eval m
			m.env.push Fn.new(@body, m.env.dup)
		end
		
		def pretty_print q
			q.text "Abs"
			q.group(4, "(", ")") {
				@body.pretty_print q
			}
		end
		alias inspect pretty_print_inspect
	end
	
	class Fn < Value
		def initialize code, env
			@code, @env = code, env
		end
		
		def app m, arg
			m.dump.push [m.code, m.env]
			m.code, m.env = @code.dup, @env.dup
			m.env.push arg
		end
	end
	
	ChurchTrue = Fn.new [Abs.new [App.new(3, 2)]], [Fn.new([], [])]
	ChurchFalse = Fn.new [Abs.new []], []
	
	class CharFn < Value
		def initialize char_code
			@char_code = char_code
		end
		attr_reader :char_code
		
		def app m, arg
			ret = @char_code == arg.char_code ? ChurchTrue : ChurchFalse
			m.env.push ret
		end
	end
	
	class Succ < Value
		def app m, arg
			m.env.push CharFn.new((arg.char_code + 1)&255)
		end
	end
	
	class Out < Value
		def app m, arg
			$stdout.print arg.char_code.chr
			$stdout.flush
			m.env.push arg
		end
	end
	
	class In < Value
		def app m, arg
			ch = $stdin.getc
			ret = ch ? CharFn.new(ch) : arg
			m.env.push ret
		end
	end
	
	
	private
	
	def eval m
		while true
			insn = m.code.shift
			if insn then
				insn.eval m
			else
				break if m.dump.empty?
				ret = m.env.last
				raise IllegalState, "no return vaule" unless ret
				m.code, m.env = m.dump.pop
				m.env.push ret
			end
		end
		raise IllegalState, "illegal final machine state" unless m.env.size == 1
		m.env.first
	end
	
	InitialEnv = [In.new, CharFn.new("M"[0]), Succ.new, Out.new]
	InitialDump = [ [ [], [] ], [ [App.new(1, 1)], [] ] ]
	
	def start code
		eval Machine.new code, InitialEnv, InitialDump
	end
	
	def parse src
		code = []
		src = src.sub(/\A[^(?:モグ)]*/u, "").gsub(/[^(?:モグ)(?:マミ)(?:ゴニョ)]/u, "")
		src.split(/(?:ゴニョ)+/u).each{|s|
			a = s.scan(/(?:(?:モグ)+)|(?:(?:マミ)+)/u)
			a = a.map {|i|
				i.split(//u).size / 2	#「モグ」も「マミ」も２文字だから。この辺り改善したい・・・
			}
			arity = 0
			arity = a.shift if /\A(?:モグ)/u =~ s
			raise "parse error at app" unless a.size % 2 == 0
			body = []
			0.step(a.size-1, 2) {|i| body.push App.new(a[i], a[i+1]) }
			insn = (0...arity).inject(body) {|body,| [Abs.new(body)] }
			code.concat insn
		}
		code
	end
	
	public
	
	def run src
		start parse(src)
	end
end

if $0 == __FILE__ then
	$stderr.puts "Charlotte #{Charlotte::RELEASE_DATE}\nMAMI MOGU MOGU GONYO" if $VERBOSE
	Charlotte.new.run $<.read
end