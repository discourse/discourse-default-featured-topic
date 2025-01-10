# frozen_string_literal: true

# name: discourse-default-featured-topic
# about: Automatically choose a featured topic for users based on their last topic in a given category
# meta_topic_id: TODO
# version: 0.0.1
# authors: Gary Pendergast (pento)
# url: https://github.com/pento/discourse-default-featured-topic
# required_version: 2.7.0

enabled_site_setting :discourse_default_featured_topic_enabled

module ::DiscourseDefaultFeaturedTopic
  PLUGIN_NAME = "discourse-default-featured-topic"
end

after_initialize do
  add_admin_route "default_featured_topic.admin.title",
                  DiscourseDefaultFeaturedTopic::PLUGIN_NAME,
                  use_new_show_route: true

  require_dependency "user_profile"

  module ::UserProfileDefaultFeaturedTopic
    module UserProfileExtension
      def featured_topic
        self[:featured_topic].presence unless SiteSetting.discourse_default_featured_topic_category

        self[:featured_topic].presence ||
          Topic
            .order(created_at: :desc)
            .where(
              category_id:
                SiteSetting.discourse_default_featured_topic_category.split("|").map(&:to_i),
            )
            .find_by(user_id: user_id)
      end
    end
  end

  UserProfile.prepend UserProfileDefaultFeaturedTopic::UserProfileExtension
end
