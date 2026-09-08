class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, limit: 20, null: false
      t.string :email, limit: 255, null: false
      t.string :password_digest, limit: 255, null: false
      t.string :password_reset_token_digest, limit: 255
      t.datetime :password_reset_expires_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :password_reset_token_digest, unique: true
  end
end
