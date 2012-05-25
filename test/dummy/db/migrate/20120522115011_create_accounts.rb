class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :name
      t.string :type
      t.references :client
      t.references :created_by

      t.timestamps
    end
  end
end
