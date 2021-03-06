Given /^I have a plugin "([^\"]+)"$/ do |name|
  plugin = Factory(:plugin, :name => name)
  PluginOwnership.create!(:plugin => plugin, :user => @me)
end

Given /^a plugin "([^\"]+)" exists$/ do |name|
  plugin = Factory(:plugin, :name => name)
  PluginOwnership.create!(:plugin => plugin, :user => Factory(:email_confirmed_user))
end

Given /^a plugin "([^\"]+)" exists with the latest version$/ do |name|
  plugin = Factory(:plugin, :name => name, :uri => @git_repo)
  plugin.fetch_latest_version
  PluginOwnership.create!(:plugin => plugin, :user => Factory(:email_confirmed_user))
end

Then /^I should see the link source "([^\"]+)"$/ do |uri|
  assert_select "a[href=#{uri}]"
end

Then /^I should see the json of "([^\"]+)"$/ do |name|
  plugin = Plugin.find_by_name!(name)
  assert_equal plugin.to_json, response.body
end

Then /^I fill in "Git URI" with the git repo$/ do
  fill_in("Git URI", :with => @git_repo)
end

When /^I push plugin with git uri "([^\"]+)"$/ do |uri|
  me = User.last
  header("Authorization", me.api_key)
  visit api_v1_plugins_path(:plugin => {:uri => uri }, :format => 'json'), :post
end
