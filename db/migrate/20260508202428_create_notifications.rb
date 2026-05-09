class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :source, null: false, foreign_key: true
      t.string :title
      t.text :body
      t.string :url
      t.datetime :received_at
      t.datetime :pushed_at
      t.text :raw_payload

      t.timestamps
    end
  end
end
