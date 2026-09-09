require "rails_helper"

RSpec.describe "Authentication and logout", type: :request do
  let(:user) { create(:user) }

  ["/tree", "/emotion_records/new", "/calendar", "/mypage"].each do |path|
    describe "GET #{path}" do
      it "redirects an unauthenticated user to login" do
        get path

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(login_path)
        expect(session[:user_id]).to be_nil

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.at_css("h1").text).to eq("ログイン")
      end

      it "allows an authenticated user to access the page" do
        post login_path, params: { session: { email: user.email, password: user.password } }

        get path

        expect(response).to have_http_status(:ok)
        expect(session[:user_id]).to eq(user.id)
      end

      it "treats a session whose user no longer exists as unauthenticated" do
        post login_path, params: { session: { email: user.email, password: user.password } }
        user.destroy!

        get path

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(login_path)
      end

      it "denies access after logout" do
        post login_path, params: { session: { email: user.email, password: user.password } }
        delete logout_path

        get path

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(login_path)
        expect(session[:user_id]).to be_nil
      end
    end
  end

  ["/", "/users/new", "/login", "/terms", "/privacy"].each do |path|
    it "allows unauthenticated access to #{path}" do
      get path

      expect(response).to have_http_status(:ok)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "DELETE /logout" do
    it "resets the session and redirects to TOP with 303" do
      post login_path, params: { session: { email: user.email, password: user.password } }
      previous_session_id = session.id.to_s
      expect(previous_session_id).to be_present
      expect(session[:user_id]).to eq(user.id)

      delete logout_path

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
      expect(session.to_hash.except("session_id", "_csrf_token")).to be_empty
      expect(session.id.to_s).not_to eq(previous_session_id)

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(session[:user_id]).to be_nil
    end

    it "redirects an already logged-out user to TOP" do
      delete logout_path

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil
    end
  end

  it "connects the existing confirmation dialog to an enabled DELETE form" do
    post login_path, params: { session: { email: user.email, password: user.password } }

    get mypage_path

    form = response.parsed_body.at_css('dialog#logout-confirmation form[action="/logout"][method="post"]')
    expect(form).to be_present
    expect(form.at_css('input[name="_method"]')["value"]).to eq("delete")
    expect(form.at_css('button[type="submit"]')).to be_present
    expect(form.at_css('button[type="submit"][disabled]')).to be_nil
    expect(form.at_css('button[type="button"][data-action="logout-confirmation#close"]')).to be_present
  end

  it "does not log out through a GET request" do
    post login_path, params: { session: { email: user.email, password: user.password } }

    get logout_path

    expect(response).to have_http_status(:not_found)
    get mypage_path
    expect(response).to have_http_status(:ok)
    expect(session[:user_id]).to eq(user.id)
  end

  context "with CSRF protection enabled" do
    around do |example|
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    before do
      get login_path
      token = response.parsed_body.at_css('input[name="authenticity_token"]')["value"]
      post login_path, params: {
        authenticity_token: token,
        session: { email: user.email, password: user.password }
      }
      expect(session[:user_id]).to eq(user.id)
    end

    it "rejects a logout request without a CSRF token and keeps the user logged in" do
      delete logout_path

      expect(response).to have_http_status(422)
      get mypage_path
      expect(response).to have_http_status(:ok)
      expect(session[:user_id]).to eq(user.id)
    end

    it "accepts the confirmation form with its CSRF token and DELETE method override" do
      get mypage_path
      form = response.parsed_body.at_css('dialog#logout-confirmation form')

      post logout_path, params: {
        _method: form.at_css('input[name="_method"]')["value"],
        authenticity_token: form.at_css('input[name="authenticity_token"]')["value"]
      }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil
    end
  end
end
