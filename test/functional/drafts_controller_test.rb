require File.dirname(__FILE__) + '/../test_helper'

class DraftsControllerTest < ActionController::TestCase
  fixtures :drafts, :issues, :users

  def setup
    @controller = DraftsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user_id] = nil
    Setting.default_language = 'en'
  end

  def test_anonymous_user_cannot_create_a_draft
    xhr :post, :create
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fdrafts'
  end
  
  def test_save_draft_for_existing_issue
    @request.session[:user_id] = 1
    xhr :post, :create,
              {:issue_id => 1,
               :user_id => 1,
               :issue => { :lock_version => "8", 
                           :subject => "Changed the subject" },
               :notes => "Just a first try to add a note"
              }
    assert_response :success
    draft = Draft.find_for_issue(:element_id => 1, :user_id => 1, :element_lock_version => 8)
    assert_not_nil draft
    assert_equal ["issue", "notes"], draft.content.keys.sort
    assert_equal "Changed the subject", draft.content[:issue][:subject]
    
    xhr :post, :create,
              {:issue_id => 1,
               :notes => "Ok, let's change this note entirely but keep the same lock version",
               :user_id => 1,
               :issue => { :lock_version => "8",
                           :subject => "Changed the subject again !" }
              }
    assert_equal 1, Draft.count(:conditions => {:element_type => 'Issue', 
                                                :element_id => 1,
                                                :element_lock_version => 8,
                                                :user_id => 1})
    draft = Draft.find_for_issue(:element_id => 1, :user_id => 1, :element_lock_version => 8)
    assert_equal "Changed the subject again !", draft.content[:issue][:subject]
  end
end
