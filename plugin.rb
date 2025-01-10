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

  add_to_serializer(:user_card, :featured_topic) do
    # Default to the user's featured topic, if they have one set
    if object.user_profile.featured_topic.present?
      return(
        BasicTopicSerializer.new(
          object.user_profile.featured_topic,
          scope: scope,
          root: false,
        ).as_json
      )
    end

    # Don't show the default featured topic if the user is editing their profile
    return if scope.request.referer.ends_with?("/u/#{object.username_lower}/preferences/profile")

    # No point trying to find a featured topic if there's no default category set
    return if SiteSetting.discourse_default_featured_topic_category.blank?

    topic =
      Topic.order(created_at: :desc).find_by(
        user_id: object.id,
        category_id: SiteSetting.discourse_default_featured_topic_category,
      )

    # If we found a topic, and the user can see it, return it
    if scope.can_see_topic?(topic)
      BasicTopicSerializer.new(topic, scope: scope, root: false).as_json
    end
  end
end
