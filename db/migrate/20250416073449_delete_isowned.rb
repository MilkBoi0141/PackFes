class DeleteIsowned < ActiveRecord::Migration[6.1]
  def change
    remove_column :posts, :is_owned, :boolean
  end
end
