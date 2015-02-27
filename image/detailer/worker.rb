require 'dimensions'
require 'streamworker'
require_relative 'image_stasher'

# eventstore client will be auto set up based on
# the EVENTSTORE_URL env var

# ImageStasher API URL is set via IMAGE_STASHER_URL

handle 'tumblr' => 'image-downloaded' do |state, event|
  image_href = event[:body]['href']
  log "handling: #{image_href}"
  unless ImageStasher.exists? image_href
    log "image not yet downloaded, skipping: #{image_href}"
    next
  end
  image_data = ImageStasher.get_data image_href
  log "downloaded: #{image_data.length}"
  body = Dimensions StringIO.new(image_data)
  details = { height: body.height, width: body.width,
              type: body.instance_variable_get(:@reader).type }
  log "emitting image-detailed"
  emit 'tumblr', 'image-detailed', details
end

