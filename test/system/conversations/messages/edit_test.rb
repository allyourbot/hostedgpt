require "application_system_test_case"

class ConversationMessagesEditTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user

    @conversation = conversations(:greeting)
    visit conversation_messages_path(@conversation)
    @message = messages(:alive)
    @msg = last_user_message
    @btn = @msg.find_role("edit")
    @msg.hover
  end

  test "edit icon shows a tooltip" do
    @btn.hover
    assert_shows_tooltip @btn, "Edit"
  end

  test "clicking edit activates a form with cancel, clicking cancel reverts" do
    @btn.hover
    @btn.click

    assert_text "Cancel"
    @msg.find_role("cancel").click

    assert_no_selector "[data-role='cancel']"
  end

  test "clicking edit, changing text, saving updates the message text, previous navigates back" do
    @btn.hover
    @btn.click

    fill_in "edit-message-#{@message.id}", with: "Don't think of a pink elephant."

    assert_current_path conversation_messages_path(@conversation, version: 1)

    @msg.find_role("save").click
    assert_no_selector "[data-role='save']"

    assert_current_path conversation_messages_path(@conversation, version: 2)
    assert_text "Don't think of a pink elephant"

    @msg = last_user_message
    assert_equal "Don't think of a pink elephant.", @msg.find_role("content-text").text

    @msg.hover
    previous = @msg.find_role("previous")
    previous.hover
    previous.click

    assert_current_path conversation_messages_path(@conversation, version: 1)
    assert_text @message.content_text

    @msg = last_user_message
    assert_equal @message.content_text, @msg.find_role("content-text").text
  end
end
