class AddGuestFieldsToBookings < ActiveRecord::Migration[7.2]
  def change
    # Allow walk-in (guest) bookings at the counter without a registered account
    change_column_null :bookings, :user_id, true

    add_column :bookings, :guest_name,  :string
    add_column :bookings, :guest_phone, :string
  end
end
