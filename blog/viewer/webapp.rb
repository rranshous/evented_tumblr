require 'sinatra'
require 'thread_safe'
require 'eventstore'
require 'base64'

Thread.abort_on_exception = true

# we want to be able to answer the question
#  what blog + post did this image come from?

image_to_post = ThreadSafe::Cache.new
post_to_blog = ThreadSafe::Cache.new
blog_to_posts = ThreadSafe::Cache.new
post_to_images = ThreadSafe::Cache.new

IMAGE_STASHER_URL = ENV['IMAGE_STASHER_URL']

CONNSTRING = ENV['EVENTSTORE_URL'] || 'http://0.0.0.0:2113'
eventstore = EventStore::Client.new(CONNSTRING)

Thread.new do
  EventStore::Util.poll(eventstore, 'tumblr').each do |event|
    next if event[:type] != 'new-image-observed'
    next if event[:body]['post'].nil?
    image_to_post[event[:body]['href']] = event[:body]['post']['href']
    (post_to_images[event[:body]['post']['href']] ||= []) << event[:body]['href']
  end
end

Thread.new do
  EventStore::Util.poll(eventstore, 'tumblr').each do |event|
    next if event[:type] != 'new-post-observed'
    post_to_blog[event[:body]['href']] = event[:body]['blog']['href']
    (blog_to_posts[event[:body]['blog']['href']] ||= []) << event[:body]['href']
  end
end

get '/links' do
  etag image_to_post.keys.length
  content_type :html
  image_to_post.keys.map do |image_href|
    "http://#{request.host}:#{request.port}/#{Base64.urlsafe_encode64(image_href)}"
  end.reduce("") do |acc, url|
    acc + "<a href='#{url}/html'>#{url}/html</a><br/>"
  end
end

get '/:image_href_encoded/html' do |image_href_encoded|
  image_href = Base64.urlsafe_decode64 image_href_encoded
  content_type :html
  puts "HREF: #{image_href}"
  post_href = image_to_post[image_href]
  blog_href = post_to_blog[post_href]
  """
  <h1>#{image_href}</h1>
  <h2>#{post_href}</h2>
  <h3>#{blog_href}</h3>
  <img src='#{IMAGE_STASHER_URL}/#{image_href_encoded}'/>
  """
end

get '/favicon.ico' do
  ''
end
