require 'dimensions'
require_relative 'streamworker'
require_relative 'image_stasher'

# eventstore client will be auto set up based on
# the EVENTSTORE_URL env var

# ImageStasher API URL is set via IMAGE_STASHER_URL

handle 'new-images' do |state, event|
  puts "STATE: #{state}"
  puts "HANDLING: #{event}"
  image_data = ImageStasher.get_data event[:body]['href']
  puts "DATA: #{image_data.length}"
  body = Dimensions StringIO.new(image_data)
  details = { height: body.height, width: body.width,
              type: body.instance_variable_get(:@reader).type }
  puts "DETAILS: #{details}"
  emit 'images', 'detailed', details
  state[:count] = 0 unless state[:count]
  state[:count] += 1
end

