class Payment < ApplicationRecord
  belongs_to :booking

  # Column is `method` — use prefix to avoid collision with Ruby's Kernel#method
  enum :method, { cash: 0, card: 1, vnpay: 2, momo: 3 }, default: :cash, prefix: :pay_by
  enum :status, { pending: 0, completed: 1, failed: 2, refunded: 3 }, default: :pending

  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :successful, -> { completed }
  scope :recent,     -> { order(created_at: :desc) }
end
