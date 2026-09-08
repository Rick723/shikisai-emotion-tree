require "rails_helper"

RSpec.describe "Signup", type: :request do
  let(:valid_attributes) do
    {
      name: "新しいユーザー",
      email: "signup@example.com",
      password: "signup-password123",
      password_confirmation: "signup-password123"
    }
  end

  describe "GET /users/new" do
    it "renders an enabled signup form with the existing navigation links" do
      get new_user_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('form[action="/users"][method="post"]')).to be_present
      expect(response.parsed_body.css('input[name^="user["]').map { |field| field["name"] }).to eq(
        ["user[name]", "user[email]", "user[password]", "user[password_confirmation]"]
      )
      expect(response.parsed_body.css('input[type="password"]').map { |field| field["autocomplete"] }).to eq(
        ["new-password", "new-password"]
      )
      expect(response.parsed_body.at_css('input[type="submit"][disabled]')).to be_nil
      expect(response.parsed_body.at_css('a[href="/terms"]')).to be_present
      expect(response.parsed_body.at_css('a[href="/privacy"]')).to be_present
      expect(response.parsed_body.at_css('a[href="/login"]')).to be_present
    end
  end

  describe "POST /users" do
    it "creates a user and redirects to login without signing them in" do
      expect {
        post users_path, params: { user: valid_attributes }
      }.to change(User, :count).by(1)

      user = User.find_by!(email: valid_attributes[:email])
      expect(user.name).to eq(valid_attributes[:name])
      expect(user.authenticate(valid_attributes[:password])).to eq(user)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(login_path)
      expect(session[:user_id]).to be_nil

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css("h1").text).to eq("ログイン")
      expect(session[:user_id]).to be_nil
    end

    it "ignores attributes outside the signup fields" do
      supplied_time = 1.year.ago
      attributes = valid_attributes.merge(
        id: 999_999,
        password_digest: "injected-digest",
        password_reset_token_digest: "injected-reset-token",
        password_reset_expires_at: supplied_time,
        created_at: supplied_time
      )

      expect {
        post users_path, params: { user: attributes }
      }.to change(User, :count).by(1)

      user = User.find_by!(email: valid_attributes[:email])
      expect(response).to redirect_to(login_path)
      expect(user.id).not_to eq(attributes[:id])
      expect(user.authenticate(valid_attributes[:password])).to eq(user)
      expect(user.password_reset_token_digest).to be_nil
      expect(user.password_reset_expires_at).to be_nil
      expect(user.created_at).to be > supplied_time
      expect(session[:user_id]).to be_nil
    end

    shared_examples "a rejected signup" do
      it "renders validation errors with 422, retains name and email, and omits both passwords" do
        expect {
          post users_path, params: { user: attributes }
        }.not_to change(User, :count)

        expect(response).to have_http_status(422)
        expect(response.parsed_body.at_css("h1").text).to eq("新規登録")
        expect(response.parsed_body.at_css('form[action="/users"][method="post"]')).to be_present
        expect(response.parsed_body.at_css('[role="alert"]').text).to include(error_message)
        expect(response.parsed_body.at_css('input[name="user[name]"]')["value"].to_s).to eq(attributes[:name])
        expect(response.parsed_body.at_css('input[name="user[email]"]')["value"].to_s).to eq(attributes[:email])
        expect(response.parsed_body.css('input[type="password"]').size).to eq(2)
        response.parsed_body.css('input[type="password"]').each do |field|
          expect(field["value"]).to be_blank
        end
        attributes.values_at(:password, :password_confirmation).select(&:present?).each do |password|
          expect(response.body).not_to include(password)
        end
        expect(session[:user_id]).to be_nil
      end
    end

    context "with a blank name" do
      let(:attributes) { valid_attributes.merge(name: "") }
      let(:error_message) { "ユーザー名 を入力してください" }

      include_examples "a rejected signup"
    end

    context "with a name longer than 20 characters" do
      let(:attributes) { valid_attributes.merge(name: "あ" * 21) }
      let(:error_message) { "ユーザー名 は20文字以内で入力してください" }

      include_examples "a rejected signup"
    end

    context "with an invalid email" do
      let(:attributes) { valid_attributes.merge(email: "invalid-email") }
      let(:error_message) { "メールアドレス は不正な値です" }

      include_examples "a rejected signup"
    end

    context "with an email already in use" do
      let(:attributes) { valid_attributes }
      let(:error_message) { "メールアドレス はすでに使用されています" }

      before { create(:user, email: valid_attributes[:email]) }

      include_examples "a rejected signup"
    end

    context "with a blank password" do
      let(:attributes) { valid_attributes.merge(password: "", password_confirmation: "") }
      let(:error_message) { "パスワード を入力してください" }

      include_examples "a rejected signup"
    end

    context "with a short password" do
      let(:attributes) { valid_attributes.merge(password: "shortpw", password_confirmation: "shortpw") }
      let(:error_message) { "パスワード は8文字以上で入力してください" }

      include_examples "a rejected signup"
    end

    context "with mismatched password confirmation" do
      let(:attributes) { valid_attributes.merge(password_confirmation: "different-confirmation123") }
      let(:error_message) { "パスワード（確認） がパスワードと一致しません" }

      include_examples "a rejected signup"
    end

    it "escapes retained input in the error response" do
      attributes = valid_attributes.merge(name: '<script>x</script>', email: '"><script>x</script>')

      post users_path, params: { user: attributes }

      expect(response).to have_http_status(422)
      expect(response.parsed_body.at_css('input[name="user[name]"]')["value"]).to eq(attributes[:name])
      expect(response.parsed_body.at_css('input[name="user[email]"]')["value"]).to eq(attributes[:email])
      expect(response.body).not_to include("<script>x</script>")
    end
  end
end
