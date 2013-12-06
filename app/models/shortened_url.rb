class ShortenedUrl < ActiveRecord::Base
  attr_accessible :long_url, :short_url, :submitter_id
  validates :long_url, :short_url, :submitter_id, :presence => true
  validates :long_url, :short_url, :uniqueness => true
  validates :long_url, length: { maximum: 1024 }
  validate :less_than_five_in_the_last_minute?

  belongs_to(
    :submitter,
    :class_name => "User",
    :foreign_key => :submitter_id,
    :primary_key => :id
  )

  has_many(
    :visits,
    :class_name => "Visit",
    :foreign_key => :visited_url_id,
    :primary_key => :id
  )

  has_many(
    :visitors,
    :through => :visits,
    :source => :visitor, uniq: true
  )

  has_many(
    :taggings,
    :class_name => "Tagging",
    :foreign_key => :shortened_url_id,
    :primary_key => :id
  )

  has_many(
    :tag_topics,
    :through => :taggings,
    :source => :tag_topic
  )

  def self.random_code
    url = nil
    while url.nil? || ShortenedUrl.find_by_short_url(url)
      url = SecureRandom.urlsafe_base64(16)
    end
    url
  end

  def self.create_for_user_and_long_url!(user, long_url)
    url_obj = ShortenedUrl.new({:long_url => long_url,
                                :short_url => ShortenedUrl.random_code,
                                :submitter_id => user.id})
    url_obj.save!
    url_obj
  end

  def num_clicks
    self.visits.count
  end

  def num_uniques
    self.visits.count :visitor_id, distinct: true
  end

  def num_recent_uniques
    self.visits.where("updated_at > ?", Time.now - 600 ).count :visitor_id, distinct: true
    #self.visits.count(conditions: "updated_at > #{Time.now - 600}", distinct: true )
  end

  def less_than_five_in_the_last_minute?
    ShortenedUrl.where("submitter_id = #{self.submitter_id} AND updated_at > ?", Time.now - 60).count < 6
  end

end
