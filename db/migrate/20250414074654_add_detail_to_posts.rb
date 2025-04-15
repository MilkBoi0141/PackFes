class AddDetailToPosts < ActiveRecord::Migration[6.1]
  def change
    add_column :posts, :detail, :string
  end
end
