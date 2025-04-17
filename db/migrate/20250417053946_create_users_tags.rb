class CreateUsersTags < ActiveRecord::Migration[6.1]
  def change
    create_table :users_tags do |t|
      t.integer :user_id
      t.integer :tag_id
      t.timestamps
    end
  end
end
