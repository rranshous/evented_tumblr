require 'sinatra'
require 'eventstore'
require 'base64'

Thread.abort_on_exception = true

# we want to be able to answer the question
#  what blog + post did this image come from?

image_to_post = {}
post_to_blog = {}
blog_to_posts = {}
post_to_images = {}
blogs = []

IMAGE_STASHER_URL = ENV['IMAGE_STASHER_URL']

CONNSTRING = ENV['EVENTSTORE_URL'] || 'http://0.0.0.0:2113'
eventstore = EventStore::Client.new(CONNSTRING)

Thread.new(image_to_post, post_to_images) do |image_to_post, pots_to_images|
  EventStore::Util.poll(eventstore, 'tumblr').each do |event|
    next if event[:type] != 'new-image-observed'
    next if event[:body]['post'].nil?
    image_to_post[event[:body]['href']] = event[:body]['post']['href']
    (post_to_images[event[:body]['post']['href']] ||= []) << event[:body]['href']
  end
end

Thread.new(post_to_blog, blog_to_posts) do |post_to_blog, blog_to_posts|
  EventStore::Util.poll(eventstore, 'tumblr').each do |event|
    next if event[:type] != 'new-post-observed'
    post_to_blog[event[:body]['href']] = event[:body]['blog']['href']
    (blog_to_posts[event[:body]['blog']['href']] ||= []) << event[:body]['href']
  end
end

Thread.new(blogs) do |blogs|
  EventStore::Util.poll(eventstore, 'tumblr').each do |event|
    next if event[:type] != 'new-blog-observed'
    blogs << event[:body]['href']
  end
end

get '/' do
  content_type :json
  etag blogs.keys.length
  blogs.to_json
end

get '/:image_href_encoded' do |image_href_encoded|
  image_href = Base64.urlsafe_decode64 image_href_encoded
  content_type :json
  puts "HREF: #{image_href}"
  post_href = image_to_post[image_href]
  blog_href = post_to_blog[post_href]
  { href: image_href, post: { href: post_href }, blog: { href: blog_href }}.to_json
end
