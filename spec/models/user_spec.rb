require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    it "builds and saves a valid user" do
      user = build(:user)

      expect(user).to be_valid
      expect { user.save! }.to change(described_class, :count).by(1)
      expect(create(:user)).to be_persisted
    end
  end

  describe "name" do
    it "requires a name" do
      user = build(:user, name: nil)

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:name, :blank)).to be true
    end

    it "accepts 20 characters and rejects 21 characters" do
      user = build(:user, name: "あ" * 20)
      expect(user).to be_valid

      user.name += "あ"
      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:name, :too_long)).to be true
    end
  end

  describe "email" do
    it "requires an email" do
      user = build(:user, email: nil)

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:email, :blank)).to be true
    end

    it "rejects an invalid format" do
      user = build(:user, email: "invalid-email")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:email, :invalid)).to be true
    end

    it "accepts 255 characters and rejects 256 characters" do
      user = build(:user, email: "#{'a' * 64}@#{'b' * 63}.#{'c' * 63}.#{'d' * 58}.com")
      expect(user.email.length).to eq(255)
      expect(user).to be_valid

      user.email = "a#{user.email}"
      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:email, :too_long)).to be true
    end

    it "saves email in lowercase" do
      user = create(:user, email: "User@Example.COM")

      expect(user.reload.email).to eq("user@example.com")
    end

    it "rejects duplicates including different letter cases" do
      create(:user, email: "user@example.com")
      user = build(:user, email: "USER@EXAMPLE.COM")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:email, :taken)).to be true
    end
  end

  describe "password" do
    it "requires a password on creation" do
      user = build(:user, password: nil)

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:password, :blank)).to be true
    end

    it "accepts 8 characters and rejects 7 characters" do
      user = build(:user, password: "a" * 8)
      expect(user).to be_valid

      user.password = user.password_confirmation = "a" * 7
      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:password, :too_short)).to be true
    end

    it "rejects a mismatched confirmation" do
      user = build(:user, password_confirmation: "different-password")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:password_confirmation, :confirmation)).to be true
    end

    it "persists a bcrypt digest without plaintext password columns" do
      user = create(:user, password: "password123")
      stored_user = described_class.find(user.id)

      expect(stored_user.password_digest).not_to eq("password123")
      expect(BCrypt::Password.new(stored_user.password_digest)).to eq("password123")
      expect(stored_user.attributes.keys).not_to include("password", "password_confirmation")
      expect(stored_user.password).to be_nil
      expect(stored_user.password_confirmation).to be_nil
    end

    it "authenticates the correct password and rejects an incorrect password" do
      user = described_class.find(create(:user, password: "password123").id)

      expect(user.authenticate("password123")).to eq(user)
      expect(user.authenticate("incorrect-password")).to be false
    end

    it "can save an existing user without assigning a password again" do
      user = described_class.find(create(:user).id)

      expect { user.update!(name: "変更後") }.not_to change(user, :password_digest)
    end
  end
end
