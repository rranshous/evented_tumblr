# GOAL
# watch for new blogs
# scrape / observe the posts for new blogs

require 'uri'
require 'feedjira'
require 'streamworker'

name 'historical-post-scraper'

handle 'tumblr' => 'new-blog-observed' do |state, event, redis|
  join = lambda { |*args|
    args.map { |arg| arg.gsub(%r{^/*(.*?)/*$}, '\1') }.join("/")
  }
  blog_href = event[:body]['href']
  if blog_href.nil? || blog_href.chomp == ''
    log "bad blog href: #{blog_href}"
    next
  end
  if redis.sismember 'finished', blog_href
    log "scrape finished, skipping: #{blog_href}"
    next
  end
  log "handling: #{blog_href}"
  last_page = nil
  post_count = 0
  (1..1000).each do |page_number|
    urls = [join.call(blog_href,'/page/',"/#{page_number}/",'rss').to_s]
    log "url: #{urls.last}"
    feed = Feedjira::Feed.fetch_and_parse(urls)[urls.first]
    if feed.is_a?(Fixnum)
      log "bad page feed: #{feed}"
    else
      if feed.entries.length == 0
        log "end of blog found [#{blog_href}]: #{page_number}"
        break
      end
      feed.entries.each do |entry|
        if redis.sismember 'entry_seen', entry.url
          log "handled post, skipping: #{entry.url}"
          next
        end
        log "handling post [#{post_count+1}]: #{entry.url}"
        post_data = {
          'href' => entry.url,
          'blog' => { 'href' => feed.url },
          'timestamp' => entry.published.iso8601
        }
        log "emit observed_post: #{entry.url}"
        emit 'tumblr', 'observed-post', post_data
        redis.sadd 'entry_seen', entry.url
        post_count += 1
      end
    end
    last_page = page_number
  end
  emit 'tumblr', 'finished-scrape', {
    'href' => blog_href,
    'num_pages_scraped' => last_page,
    'num_posts_observed' => post_count
  }
  redis.sadd 'finished', blog_href
end

at_exit { puts "ERROR: #{$!}" unless $!.nil? }
