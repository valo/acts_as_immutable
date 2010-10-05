ActiveRecord::Schema.define do
  create_table :payments, :force => true do |t|
    t.string :customer
    t.decimal :amount
    t.string :status
  end
end