require "rails_helper"

RSpec.describe "Login", type: :request do
  let(:password) { "login-password123" }
  let(:user) { create(:user, password: password) }
  let(:failure_message) { "メールアドレスまたはパスワードが正しくありません。" }

  describe "GET /login" do
    it "renders a login form and preserves the signup link" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('form[action="/login"][method="post"]')).to be_present
      expect(response.parsed_body.at_css('input[name="session[email]"]')['autocomplete']).to eq("email")
      expect(response.parsed_body.at_css('input[name="session[password]"]')['autocomplete']).to eq("current-password")
      expect(response.parsed_body.at_css('input[type="submit"][disabled]')).to be_nil
      expect(response.parsed_body.at_css('a[href="/users/new"]')).to be_present
    end
  end

  describe "POST /login" do
    it "authenticates the user, stores only their ID, and redirects to the tree" do
      post login_path, params: { session: { email: user.email, password: password } }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(tree_path)
      expect(session.to_hash.except("session_id", "_csrf_token")).to eq("user_id" => user.id)

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(session[:user_id]).to eq(user.id)
    end

    it "accepts email letter cases consistently with the User model" do
      post login_path, params: { session: { email: user.email.upcase, password: password } }

      expect(response).to redirect_to(tree_path)
      expect(session[:user_id]).to eq(user.id)
    end

    it "replaces the existing session ID on successful authentication" do
      post login_path, params: { session: { email: user.email, password: password } }
      previous_session_id = session.id.to_s
      expect(previous_session_id).to be_present

      post login_path, params: { session: { email: user.email, password: password } }

      expect(response).to redirect_to(tree_path)
      expect(session.id.to_s).not_to eq(previous_session_id)
      expect(session[:user_id]).to eq(user.id)
    end

    shared_examples "a failed login" do
      it "renders the same error with 422, without authentication or the submitted password" do
        post login_path, params: { session: { email: email, password: submitted_password } }

        expect(response).to have_http_status(422)
        expect(session[:user_id]).to be_nil
        expect(response.parsed_body.at_css("h1").text).to eq("ログイン")
        expect(response.parsed_body.css('[role="alert"]').map(&:text)).to eq([failure_message])
        expect(response.parsed_body.at_css('form[action="/login"][method="post"]')).to be_present
        expect(response.parsed_body.at_css('input[type="password"]')["value"]).to be_blank
        expect(response.body).not_to include(submitted_password) if submitted_password.present?
      end
    end

    context "with an incorrect password" do
      let(:email) { user.email }
      let(:submitted_password) { "incorrect-password123" }

      include_examples "a failed login"
    end

    context "with an unregistered email" do
      let(:email) { "unregistered@example.com" }
      let(:submitted_password) { "incorrect-password123" }

      include_examples "a failed login"

      it "does not distinguish a missing user from an incorrect password in the rendered page" do
        post login_path, params: { session: { email: user.email, password: submitted_password } }
        incorrect_password_page = response.parsed_body
        incorrect_password_page.at_css('input[type="email"]').remove_attribute("value")

        post login_path, params: { session: { email: email, password: submitted_password } }
        unregistered_email_page = response.parsed_body
        unregistered_email_page.at_css('input[type="email"]').remove_attribute("value")

        expect(unregistered_email_page.to_html).to eq(incorrect_password_page.to_html)
        expect(session[:user_id]).to be_nil
      end
    end

    context "with a blank password" do
      let(:email) { user.email }
      let(:submitted_password) { "" }

      include_examples "a failed login"
    end
  end
end
