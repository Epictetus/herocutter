require 'test_helper'

class PluginsControllerTest < ActionController::TestCase
  context "when logged in" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end

    context "on GET new" do
      setup do
        get :new
      end
      
      should_respond_with :success
      should_render_template :new
      should_assign_to :plugin, :class => Plugin
    end

    context "on POST create" do
      setup do
        @plugin_params = {:name => "new_plugin", :uri => "git://github.com/justinfrench/formtastic.git" }
      end

      context "with valid data" do
        setup do
          post :create, :plugin => @plugin_params
        end

        should_create :plugin
        should_create :plugin_ownership
        should_create Delayed::Job
        should_respond_with :redirect
        should_redirect_to('the show plugin page') { plugin_path(assigns(:plugin)) }
        should "have the logged in user own the plugin" do
          assert_equal @user, assigns(:plugin_ownership).user
        end
      end

      context "with a plugin that has a prefix 'heroku_'" do
        setup do
          @plugin_params[:name] = "heroku_new_plugin"
          post :create, :plugin => @plugin_params
        end

        should_create :plugin
        should_create :plugin_ownership
        should_create Delayed::Job
        should_respond_with :redirect
        should_redirect_to('the show plugin page') { plugin_path(assigns(:plugin)) }
        should "have the logged in user own the plugin" do
          assert_equal @user, assigns(:plugin_ownership).user
        end
        should "have the name new_plugin" do
          assert_equal "new_plugin", assigns(:plugin).name
        end
      end

      context "with problems" do
        context "with URI parse" do
          setup do
            post :create
          end

          should_respond_with :success
          should_render_template :new
          should_assign_to :plugin, :class => Plugin
          should_not_change("Plugin count") { Plugin.count }
          should_not_change("PluginOwnership count") { PluginOwnership.count }
        end

        context "with plugin data" do
          setup do
            stub.instance_of(Plugin).save! { raise ActiveRecord::RecordInvalid.new(Plugin.new) }
            post :create, :plugin => @plugin_params
          end

          should_respond_with :success
          should_render_template :new
          should_assign_to :plugin, :class => Plugin
          should_not_change("Plugin count") { Plugin.count }
          should_not_change("PluginOwnership count") { PluginOwnership.count }
        end

        context "with PluginOwnership" do
          setup do
            stub.instance_of(PluginOwnership).save! { raise ActiveRecord::RecordInvalid.new(PluginOwnership.new) }
            post :create, :plugin => @plugin_params
          end

          should_respond_with :success
          should_render_template :new
          should_assign_to :plugin, :class => Plugin
          should_assign_to :plugin_ownership, :class => PluginOwnership
          should_not_change("Plugin count") { Plugin.count }
          should_not_change("PluginOwnership count") { PluginOwnership.count }
        end
      end
    end

    context "on GET edit" do
      setup do
        @plugin = Factory(:plugin)
        get :edit, :id => @plugin.id
      end

      should_respond_with :success
      should_render_template :edit
      should_assign_to(:plugin) { @plugin }
    end

    context "on PUT update" do
      setup do
        @plugin = Factory(:plugin)
      end

      context "with valid data" do
        setup do
          @new_uri = "git://github.com/new_uri.git"
          put :update, { :id => @plugin.id, :plugin => {:uri => @new_uri } }
        end

        should_respond_with :redirect
        should_redirect_to('the show plugin page') { plugin_path(@plugin) }
        should_assign_to(:plugin) { @plugin }
        should "change the uri of the plugin" do
          assert_equal @new_uri, assigns(:plugin).uri
        end
      end

      context "with plugin problems" do
        setup do
          @plugin = Factory.stub(:plugin)
          stub(Plugin).find_by_id(@plugin.id.to_s) { @plugin }
          stub(@plugin).update_attributes { false }
          put :update, :id => @plugin.id
        end

        should_respond_with :success
        should_render_template :edit
        should_assign_to(:plugin) { @plugin }
      end
    end
  end

  context "without being logged in" do
    context "on GET index" do
      setup do
        @plugins = Array(1..3).collect { Factory(:plugin) }
        get :index
      end

      should_respond_with :success
      should_render_template :index
      should_assign_to(:plugins) { @plugins }
    end

    context "on GET new" do
      setup do
        get :new
      end

      should_respond_with :redirect
      should_redirect_to('the hompage') { root_url }
    end

    context "on POST create" do
      setup do
        post :create
      end

      should_respond_with :redirect
      should_redirect_to('the hompage') { root_url }
    end

    context "when plugin exists" do
      setup do
        @plugin = Factory(:plugin)
      end

      context "and there's a version" do
        setup do
          @versions = Array(1..5).collect { Factory(:version, :plugin => @plugin) }
          @version = Factory(:version, :plugin => @plugin)
          @versions << @version
        end

        context "on GET show" do
          setup do
            get :show, :id => @plugin.id
          end

          should_respond_with :success
          should_render_template :show
          should_assign_to(:plugin) { @plugin }
          should_assign_to(:latest_version) { @version }
          should_assign_to(:versions) { @versions[1,5].reverse }
          should_not_change("Download count") { Download.count }
        end
      end

      context "and there's not a version" do
        context "on GET show" do
          setup do
            get :show, :id => @plugin.id
          end

          should_respond_with :success
          should_render_template :show
          should_assign_to(:plugin) { @plugin }
          should_not_assign_to(:latest_version)
          should_assign_to(:versions) { Array.new }
          should_not_change("Download count") { Download.count }
        end
      end
    end

    context "when plugin doesn't exist" do
      context "on GET show" do
        setup do
          get :show, :id => 5
        end

        should_respond_with :success
        should_render_template :no_plugin_found
      end
    end

    context "on GET edit" do
      setup do
        @plugin = Factory(:plugin)
        get :edit, :id => @plugin.id
      end

      should_respond_with :redirect
      should_redirect_to('the homepage') { root_url }
    end

    context "on PUT update" do
      setup do
        @plugin = Factory(:plugin)
        put :update, :id => @plugin.id
      end

      should_respond_with :redirect
      should_redirect_to('the hompage') { root_url }
    end
  end
end
