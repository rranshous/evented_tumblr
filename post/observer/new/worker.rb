require 'streamworker'
require 'feedjira'
require 'thread'
require_relative 'blog_accessor'


SLEEP_TIME = ENV['SLEEP_TIME'] ? ENV['SLEEP_TIME'].to_i : 60 * 10

name 'new-post-poller'

loop do
  BlogAccessor.blogs.each do |blog_href|
    url = "#{blog_href}/rss"
    log "handling: #{blog_href}"
    feed = Feedjira::Feed.fetch_and_parse([url])[url]
    if feed.is_a?(Fixnum)
      log "could not fetch feed data: #{feed}"
      emit 'tumblr', 'blog-not-found', {
        href: blog_href,
        url: url,
        response: feed
      }
      next
    end
    feed.entries.each do |entry|
      post_data = {
        'href' => entry.url,
        'blog' => { 'href' => feed.url },
        'timestamp' => entry.published.iso8601
      }
      log "emitting post-observed #{entry.url}"
      emit 'tumblr', 'post-observed', post_data
    end
  end
  log 'sleeping'
  sleep SLEEP_TIME
end
