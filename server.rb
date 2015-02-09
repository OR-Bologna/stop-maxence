#!/usr/bin/env ruby

require "json"
require "socket"

class Server
    def initialize
        @server = TCPServer.new 1988
        @pqueue = ProcessQueue.new
        @observer = @pqueue.observer_thread
        @listener = listener_thread
    
        @observer.join
        @listener.join
    end
  
    def listener_thread
        Thread.new do
            loop do
                client = @server.accept
        
                client.puts "Welcome to the Stop Maxence daemon!\n"
                client.puts "Fighting back against the french army!\n"
        
                begin
                    request = client.gets.chomp
                rescue Exception => e
                    puts "Can't read message from client: #{e.message}"
                    break
                end
    
                errors = check_for_errors request
      
                if errors.empty?
                    message = execute request
                    client.puts({:type => "ok", :message => message}.to_json)
                else
                    client.puts errors.to_json
                end
                
                client.close
            end
        end
    end
  
    def check_for_errors request
        errors_ary = Array.new

        begin
            json_request = JSON.parse(request)
        rescue
            return {:type => "error", :errors => [{:message => "Unable to parse your request as JSON"}]}
        end

        if json_request["action"] == "sched"
            if json_request["owner"].nil? or json_request["owner"].empty?
                errors_ary << {:message => "No owner provided"}
            end
  
            if json_request["cmdline"].nil? or json_request["cmdline"].empty?
                errors_ary << {:message => "No cmdline provided"}
            end
        elsif json_request["action"] == "list"
            # All ok, no additional parameters needed
        else
            errors_ary << {:message => "Unrecognised action"}
        end

        if errors_ary.empty?
            return Hash.new
        else
            return {:type => "error", :errors => errors_ary}
        end
    end

    def execute request
        json_request = JSON.parse request

        if json_request["action"] == "sched"
            job = Job.new json_request
            @pqueue.queue.push job
            return "Scheduled, queue size: #{@pqueue.queue.size}"
        elsif json_request["action"] == "list"
            return @pqueue.queue.to_json
        end
    end
end

class ProcessQueue
    attr_accessor :queue

    def initialize
        @queue = Array.new
        @working = false
    end

    def observer_thread
        Thread.new do
            loop do
                unless @working or @queue.empty?        
                    @working = true
                    job = @queue.first
                    job.perform!
                    @queue.shift
                    @working = false
                else
                    sleep 1
                end
            end
        end
    end
end

class Serialisable
    def to_json(options = {})
        hash = {}
        self.instance_variables.each do |var|
            hash[var.to_s.delete("@")] = self.instance_variable_get var
        end
        hash.to_json
    end
end

class Job < Serialisable
    attr_accessor :status

    def initialize(params)
        @cmdline = params["cmdline"]
        @stdout = params["stdout"]
        @stderr = params["stderr"]
        @owner = params["owner"]
        @status = "queued"
    end

    def perform!
        rand_n = Random.rand(10000)
        @stdout ||= "stdout_#{@owner}_#{rand_n}"
        @stderr ||= "stderr_#{@owner}_#{rand_n}"
        @status = "running"

        Process.wait spawn(@cmdline, :out => @stdout, :err => @stderr)
        @status = "completed"
    end
end

Server.new