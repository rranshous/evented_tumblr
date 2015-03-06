require 'streamworker'
require 'httparty'

name 'image-finder'
handle 'tumblr' => 'new-post-observed' do |state, event|
  post_href = event[:body]["href"]
  log "handling: #{post_href}"
  begin
    response = HTTParty.get("#{post_href}/xml",
                            headers: {'Accept'=>'application/xml'})
  rescue SocketError => ex
    log "Exception getting post data, redoing: #{ex}"
    redo
  end
  post_data = response.parsed_response
  unless post_data.is_a? Hash
    log "could not understand data, skipping: #{post_href}/xml"
    next
  end
  post_type = post_data["tumblr"]["posts"]["post"]["type"]
  if post_type == "photo"
    image_versions = Hash[
      post_data["tumblr"]["posts"]["post"]["photo_url"]
      .map{|d| [d["max_width"].to_i, d["__content__"]] }
    ]
    image_versions.each do |width, url|
      image_data = {
        href: url,
        width: width,
        post: { href: post_href }
      }
      log "emitting image-noted #{url}"
      emit 'tumblr', 'image-noted', image_data
    end
  else
    log "not a photo post, skipping"
  end
end
