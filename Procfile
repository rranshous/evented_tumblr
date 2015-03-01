
# worker
image_detailer: sh -c 'image/detailer && bundle exec ruby worker.rb'
image_identifier: sh -c 'image/identifier && bundle exec ruby worker.rb'
image_finder: sh -c 'image/finder && bundle exec ruby worker.rb'
image_downloader: sh -c 'image/downloader && bundle exec ruby worker.rb'
blog_identifier: sh -c 'blog/identifier && bundle exec ruby worker.rb'
blog_observer: sh -c 'blog/observer && bundle exec ruby worker.rb'
blog_finder: sh -c 'blog/finder && bundle exec ruby worker.rb'
post_identifier: sh -c 'post/identifier && bundle exec ruby worker.rb'
post_observer_new: sh -c 'post/observer/new && bundle exec ruby worker.rb'
post_observer_historical: sh -c 'post/observer/historical && bundle exec ruby worker.rb'

# webapp
image_stash: sh -c 'image/stash && bundle exec ruby webapp.rb'
blog_accessor: bundle exec ruby blog/accessor/webapp.rb

# test
test: bundle exec ruby test.rb
