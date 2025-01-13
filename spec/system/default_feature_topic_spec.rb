# frozen_string_literal: true

describe "Default Featured Topic", type: :system, js: true do
  fab!(:user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, user: user, category: category) }
  fab!(:post) { Fabricate(:post, topic: topic) }
  let(:user_page) { PageObjects::Pages::User.new }
  let(:user_profile) { PageObjects::Pages::UserPreferencesProfile.new }

  before do
    SiteSetting.allow_featured_topic_on_user_profiles = true
    SiteSetting.discourse_default_featured_topic_enabled = true
    SiteSetting.discourse_default_featured_topic_category = category.id
    SiteSetting.hide_new_user_profiles = false
  end

  it "doesn't show the user's featured topic on their profile edit page" do
    sign_in(user)
    user_profile.visit(user)
    expect(page).not_to have_content(topic.title)
  end

  context "in the user's profile page" do
    it "shows the most recent topic in the category by that user" do
      topic2 = Fabricate(:topic, user: user, category: category)
      Fabricate(:post, topic: topic2)
      sign_in(user)
      user_page.visit(user).expand_info_panel
      expect(page).to have_content(topic2.title)
    end

    it "doesn't show the user's featured topic if there isn't a default category set" do
      SiteSetting.discourse_default_featured_topic_category = nil
      sign_in(user)
      user_page.visit(user).expand_info_panel
      expect(page).not_to have_content(topic.title)
    end

    it "shows the user's featured topic to anonymous users" do
      user_page.visit(user)
      expect(page).not_to have_selector("button[aria-controls='collapsed-info-panel']")
      expect(page).to have_content(topic.title)
    end
  end

  it "shows the featured topic on the popup user card" do
    sign_in(user)
    visit "/"
    find("[data-user-card='#{user.username_lower}']").click

    expect(find("#user-card .featured-topic")).to have_content(topic.title)
  end

  context "when the user can't access the category" do
    fab!(:admin)
    fab!(:private_group) { Fabricate(:group, name: "Private") }
    fab!(:private_category) do
      Fabricate(:private_category, name: "Privacy", slug: "privacy", group: private_group)
    end
    fab!(:admin_group_user) { Fabricate(:group_user, group: private_group, user: admin) }
    fab!(:private_topic) { Fabricate(:topic, user: admin, category: private_category) }
    fab!(:private_post) { Fabricate(:post, topic: private_topic) }

    before { SiteSetting.discourse_default_featured_topic_category = private_category.id }

    it "doesn't show the featured topic" do
      # Check anonymous user first
      user_page.visit(admin)
      expect(page).not_to have_selector("button[aria-controls='collapsed-info-panel']")
      expect(page).not_to have_content(private_topic.title)

      # Now check logged in user
      sign_in(user)
      user_page.visit(admin)
      expect(page).not_to have_selector("button[aria-controls='collapsed-info-panel']")
      expect(page).not_to have_content(private_topic.title)

      # Now check admin user
      sign_in(admin)
      user_page.visit(admin).expand_info_panel
      expect(page).to have_content(private_topic.title)
    end
  end
end
