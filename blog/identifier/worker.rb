require 'streamworker'

name 'new-blog-notifier'
handle 'tumblr' => 'observed-blog' do |state, event, redis|
  blog_href = event[:body]['href']
  log "handling: #{blog_href}"
  if redis.sismember('seen', blog_href)
    log "seen, skipping: #{blog_href}"
    next
  end
  log "new: #{blog_href}"
  blog_data = { href: blog_href, post: event[:body]['post'] }
  log "emitting new-blog-observed #{blog_href}"
  emit 'tumblr', 'new-blog-observed', blog_data
  redis.sadd('seen', blog_href)
end
