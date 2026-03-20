class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :booking,         null: false, foreign_key: true
      t.integer    :method,          null: false, default: 0
      t.decimal    :amount,          precision: 10, scale: 2, null: false
      t.integer    :status,          null: false, default: 0
      t.datetime   :paid_at
      t.string     :transaction_code

      t.timestamps
    end

    add_index :payments, :status
    add_index :payments, :transaction_code
  end
end
