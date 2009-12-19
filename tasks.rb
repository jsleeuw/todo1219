#!/usr/bin/env ruby
 
# Implements Tasks spec defined at: 
# http://wiki.sproutcore.com/Todos+06-Building+the+Backend
 
require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'json'
 
# connect DataMapper to a local sqlite file. 
 
#DataMapper.setup(:default, ENV['DATABASE_URL'] || 
    #{}"sqlite3://#{File.join(File.dirname(__FILE__), 'tmp', 'tasks.db')}")
 
DataMapper.setup(:default, 'sqlite3::memory:')
  
# define the Task model object we will use to store data
# in the server.  Note the three properties defined.  "id"
# will be used as the GUID for the task.
 
class Task 
  include DataMapper::Resource
  
  property :id,          Serial
  property :description, Text, :nullable => false
  property :is_done,     Boolean
 
  # helper method returns the URL for a task based on id  
 
  def url
    "/tasks/#{self.id}"
  end
 
  # helper method converts the Task to json.  Anytime you
  # call to_json on a data structure with a Task, this will
  # be used to convert the task itself
 
  def to_json(*a)
    { 
      'guid'        => self.url, 
      'description' => self.description,
      'isDone'      => self.is_done 
    }.to_json(*a)
  end
 
  # keys that MUST be found in the json
  REQUIRED = [:description, :is_done]
  
  # ensure json is safe.  If invalid json is received returns nil
  def self.parse_json(body)
    json = JSON.parse(body)
    ret = { :description => json['description'], :is_done => json['isDone'] }
    return nil if REQUIRED.find { |r| ret[r].nil? }
 
    ret 
  end
  
end
 
# instructs DataMapper to setup your database as needed
DataMapper.auto_upgrade!
 
 
# return list of all installed tasks.  Just get all tasks and
# return as JSON
get '/tasks' do
  content_type 'application/json'
  { 'content' => Array(Task.all) }.to_json
end
 
# create a new task.  request body to contain json
post '/tasks' do
  opts = Task.parse_json(request.body.read) rescue nil
  halt(401, 'Invalid Format') if opts.nil?
  
  task = Task.new(opts)
  halt(500, 'Could not save task') unless task.save
 
  response['Location'] = task.url
  response.status = 201
end
 
# Get an individual task
get "/tasks/:id" do
  task = Task.get(params[:id]) rescue nil
  halt(404, 'Not Found') if task.nil?
 
  content_type 'application/json'
  { 'content' => task }.to_json
end
 
# Update an individual task
put "/tasks/:id" do
  task = Task.get(params[:id]) rescue nil
  halt(404, 'Not Found') if task.nil?
  
  opts = Task.parse_json(request.body.read) rescue nil
  halt(401, 'Invalid Format') if opts.nil?
  
  task.description = opts[:description]
  task.is_done = opts[:is_done]
  task.save
  
  response['Content-Type'] = 'application/json'
  { 'content' => task }.to_json
end
 
# Delete an invidual task
delete '/tasks/:id' do
  task = Task.get(params[:id]) rescue nil
  task.destroy unless task.nil?
end

  