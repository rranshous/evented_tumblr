require 'streamworker'

name 'new-image-notifier'
handle 'tumblr' => 'image-noted' do |state, event, redis|
  image_href = event[:body]['href']
  if redis.sismember('seen', image_href)
    log "seen, skipping: #{image_href}"
    next
  end
  log "new: #{image_href}"
  image_data = { href: image_href, post: event[:body]['post'] }
  emit 'tumblr', 'new-image-observed', image_data
  redis.sadd('seen', image_href)
end

