require 'streamworker'

name 'new-post-notifier'
handle 'tumblr' => 'post-observed' do |state, event, redis|
  post_href = event[:body]['href']
  if redis.sismember('seen', post_href)
    log "seen, skipping: #{post_href}"
    next
  end
  log "new: #{post_href}"
  post_data = { href: post_href,
                blog: event[:body]['blog'],
                timestamp: event[:body]['timestamp'] }
  emit 'tumblr', 'new-post-observed', post_data
  redis.sadd('seen', post_href)
end
