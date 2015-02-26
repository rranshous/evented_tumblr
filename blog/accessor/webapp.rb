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

get '/' do
  etag image_to_post.keys.length
  image_to_post.keys.map do |image_href|
    "http://#{request.host}/#{Base64.urlsafe_encode64(image_href)}"
  end.to_json
end

get '/:image_href_encoded' do |image_href_encoded|
  image_href = Base64.urlsafe_decode64 image_href_encoded
  content_type :json
  puts "HREF: #{image_href}"
  post_href = image_to_post[image_href]
  blog_href = post_to_blog[post_href]
  { href: image_href, post: { href: post_href }, blog: { href: blog_href }}.to_json
end
