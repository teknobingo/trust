class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.string :name
      t.references :accountant

      t.timestamps
    end
  end
end
