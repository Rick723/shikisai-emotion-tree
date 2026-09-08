class CreateEmotions < ActiveRecord::Migration[8.1]
  def change
    create_table :emotions do |t|
      t.string :name, limit: 30, null: false
      t.string :color_code, limit: 7, null: false
      t.integer :display_order, null: false

      t.timestamps
    end

    add_index :emotions, :name, unique: true
    add_index :emotions, :display_order, unique: true
    add_check_constraint :emotions, "display_order >= 1", name: "chk_emotions_display_order_positive"
  end
end
