class CreateItems < ActiveRecord::Migration[6.1]
  def change
    create_table :items do |t|
      t.integer :post_id
      t.string :name
      t.integer :amount
      t.string :detail
      t.timestamps
    end
  end
end
