class User < ActiveRecord::Base
  attr_accessible :email
  validates :email, :presence => true
  validates :email, :uniqueness => true


  has_many(
    :submitted_urls,
    :class_name => "ShortenedUrl",
    :foreign_key => :submitter_id,
    :primary_key => :id
  )

  has_many(
  :visits,
  :class_name => "Visit",
  :foreign_key => :visitor_id,
  :primary_key => :id
  )

  has_many(
  :visited_urls,
  :through => :visits,
  :source => :visited_url, uniq: true
  )

  def create_shortened_url
    long_url = get_input("Type in your long url")
  	url_obj = ShortenedUrl.create_for_user_and_long_url!(self, long_url)
    short_url = url_obj.short_url
  	puts "Short url is: #{short_url}"

    create_tag(url_obj)
  end

  def visit_shortened_url
    short_url = get_input("Type in the shortened URL")
  	url_obj = ShortenedUrl.find_by_short_url(short_url)
  	long_url = url_obj.long_url

  	Launchy.open(long_url)
  	v = Visit.new({visitor_id: self.id, visited_url_id: url_obj.id})
  	v.save!

    create_tag(url_obj)

  end

  def create_tag(url_obj)
    tags = get_input("Please enter tags for this URL, separated by ', ' ")
    tags = tags.split(', ')
    tags.each do |tag|
      t = nil
      unless url_obj.tag_topics.pluck(:topic_name).include?(tag)
        t = TagTopic.new(topic_name: tag)
        t.save!
      else
        t = TagTopic.find_by_topic_name(tag)
      end
      tagging = Tagging.new(tag_topic_id: t.id, shortened_url_id: url_obj.id)
      tagging.save
    end
  end

end
