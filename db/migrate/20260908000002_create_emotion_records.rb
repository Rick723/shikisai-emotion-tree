class CreateEmotionRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :emotion_records do |t|
      t.references :user, null: false, index: false
      t.references :emotion, null: false
      t.integer :strength, null: false
      t.integer :afterglow, null: false
      t.decimal :position_x, precision: 5, scale: 2, null: false
      t.decimal :position_y, precision: 5, scale: 2, null: false
      t.date :felt_on, null: false
      t.time :felt_at
      t.text :memo

      t.timestamps
    end

    add_index :emotion_records, [:user_id, :felt_on]
    add_foreign_key :emotion_records, :users, on_delete: :cascade
    add_foreign_key :emotion_records, :emotions, on_delete: :restrict

    add_check_constraint :emotion_records, "strength BETWEEN 0 AND 100",
                         name: "chk_emotion_records_strength_range"
    add_check_constraint :emotion_records, "afterglow BETWEEN 0 AND 100",
                         name: "chk_emotion_records_afterglow_range"
    add_check_constraint :emotion_records, "position_x BETWEEN 0.00 AND 100.00",
                         name: "chk_emotion_records_position_x_range"
    add_check_constraint :emotion_records, "position_y BETWEEN 0.00 AND 100.00",
                         name: "chk_emotion_records_position_y_range"
  end
end
