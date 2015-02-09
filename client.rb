#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'socket'

options = Hash.new

OptionParser.new do |opts|
    ["action ACT", "owner USER", "cmdline CMD", "stdout FILE", "stderr FILE", "addr ADDRESS"].each do |opt_name|
        opts.on("--#{opt_name}") do |opt|
            options[opt_name.split.first] = opt
        end
    end
end.parse!

if options["addr"].nil? or options["addr"].empty?
    puts "No address specified, defaulting to localhost"
    options["addr"] = "localhost"
elsif options["action"].nil? or options["action"].empty?
    puts "You need to specify an action!"
    exit
elsif options["action"] == "sched" and (options["owner"].nil? or options["cmdline"].nil? or options["owner"].empty? or options["cmdline"].empty?)
    puts "You need to specify an owner and a cmdline when scheduling"
    exit
end

server = TCPSocket.open(options["addr"], 1988)

# MOTD (2 lines)
puts server.gets
puts server.gets

server.puts(options.to_json)

msg = JSON.parse(server.gets)

if msg["type"] =~ /error/
    puts "Error(s) occurred:"
    msg["errors"].each do |err|
        puts err["message"]
    end
elsif msg["type"] =~ /ok/
    if options["action"] =~ /sched/
        puts msg["message"]
    elsif options["action"] =~ /list/
        puts "Jobs queue"
        JSON.parse(msg["message"]).each_with_index do |job, i|
            puts "%3i\t%15s\t%10s\t%15s" % [i, job["owner"], job["status"], job["cmdline"]]
        end
    end
end

server.close