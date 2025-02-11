require "rails_helper"

RSpec.feature "HasManyField", type: :feature do
  let!(:user) { create :user }

  subject do
    visit url
    page
  end

  context "show" do
    # Test the frame directly
    let(:url) { "/avo/resources/users/#{user.id}/posts?turbo_frame=has_many_field_posts&view_type=table" }

    describe "without a related post" do
      it { is_expected.to have_text "No related posts found" }

      it "creates a post" do
        visit url

        click_on "Create new post"

        expect(page).to have_current_path "/avo/resources/posts/new?via_relation=user&via_relation_class=User&via_resource_id=#{user.id}"

        expect(page).to have_select "post_user_id", selected: user.name, disabled: true

        fill_in "post_name", with: "New post name"

        click_on "Save"
        wait_for_loaded

        expect(current_path).to eql "/avo/resources/users/#{user.id}"
        expect(user.posts.last.name).to eql "New post name"
        expect(user.posts.last.user_id).to eql user.id
      end
    end

    describe "with a related post" do
      let!(:post) { create :post, user: user }

      it "navigates to a view post page" do
        visit url

        click_on "Create new post"

        expect(page).to have_current_path "/avo/resources/posts/new?via_relation=user&via_relation_class=User&via_resource_id=#{user.id}"
      end

      it "displays valid links to resources" do
        visit url

        # grid view button
        expect(page).to have_link("Grid view", href: "/avo/resources/users/#{user.id}/posts?turbo_frame=has_many_field_posts&view_type=grid")

        # create new button
        expect(page).to have_link("Create new post", href: "/avo/resources/posts/new?via_relation=user&via_relation_class=User&via_resource_id=#{user.id}")

        # attach button
        expect(page).to have_link("Attach post", href: "/avo/resources/users/#{user.id}/posts/new")

        ## Table Rows
        # show link
        show_path = "/avo/resources/posts/#{post.id}?via_resource_class=User&via_resource_id=#{user.id}"
        expect(page).to have_css("a[data-control='show'][href='#{show_path}']")

        # id field show link
        expect(field_element_by_resource_id("id", post.id).native).to have_css("a[href='/avo/resources/posts/#{post.id}']")

        # edit link
        edit_path = "/avo/resources/posts/#{post.id}/edit?via_resource_class=User&via_resource_id=#{user.id}"
        expect(page).to have_selector("[data-component='resources-index'] a[data-control='edit'][data-resource-id='#{post.id}'][href='#{edit_path}']")

        # detach form
        form = "form[action='/avo/resources/users/#{user.id}/posts/#{post.id}'][data-turbo-frame='has_many_field_posts']"
        expect(page).to have_selector("[data-component='resources-index'] #{form}")
        expect(page).to have_selector(:css, "#{form} input[type='hidden'][name='_method'][value='delete']", visible: false)
        # expect(page).to have_selector(:css, "#{form} input#referrer_detach_#{post.id}[value='/avo/resources/users/#{user.id}/posts?turbo_frame=has_many_field_posts']", visible: false)
        expect(page).to have_selector("[data-component='resources-index'] #{form} button[data-control='detach'][data-resource-id='#{post.id}']")

        # destroy form
        form = "form[action='/avo/resources/posts/#{post.id}'][data-turbo-frame='has_many_field_posts']"
        expect(page).to have_selector("[data-component='resources-index'] #{form}")
        expect(page).to have_selector("#{form} input[type='hidden'][name='_method'][value='delete']", visible: false)
        # expect(page).to have_selector("#{form} input#referrer_destroy_#{post.id}[value='/avo/resources/users/#{user.id}/posts?turbo_frame=has_many_field_posts']", visible: false)
        expect(page).to have_selector("[data-component='resources-index'] #{form} button[data-control='destroy'][data-resource-id='#{post.id}']")
      end

      it "deletes a post" do
        visit url

        expect {
          find("[data-resource-id='#{post.id}'] [data-control='destroy']").click
        }.to change(Post, :count).by(-1)

        expect(page).to have_current_path url
        expect(page).not_to have_text post.name
      end

      it "detaches a post" do
        visit url

        expect {
          find("tr[data-resource-id='#{post.id}'] [data-control='detach']").click
        }.to change(user.posts, :count).by(-1)

        expect(page).to have_current_path url
        expect(page).not_to have_text post.name
      end
    end
  end
end
