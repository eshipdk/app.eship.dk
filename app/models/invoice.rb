include Economic
class Invoice < ActiveRecord::Base
  belongs_to :user
  belongs_to :affiliate, :class_name => 'User', :foreign_key => 'affiliate_id'
  has_many :shipments
  has_many :additional_charges
  has_many :rows, :class_name => 'InvoiceRow', :dependent => :destroy
  
  
  scope :filter_affiliate_withdrawal_pending, ->() {
    return self.where(:affiliate_commission_withdrawn => false).where("affiliate_commission > ?", 0) 
  }
  
  def pretty_id
    if economic_id
      economic_id
    else
      "TMP_#{id}"
    end
  end
  
  def customer
    user
  end

  def capturable?
    can_capture_online
  end
  
  def can_capture_online
    not captured_online and user.can_pay_online and economic_id
  end

  def booked?
    economic_id != nil
  end

  def editable?
    not economic_id
  end

  def compute_commissions
    self.profit = amount - cost
    if affiliate
      self.affiliate_commission =
        [0,
         (self.profit - n_shipments *
                        affiliate.affiliate_base_house_amount) *
         affiliate.affiliate_commission_rate].max
    else
      self.affiliate_commission = 0
    end
    self.house_commission = profit - affiliate_commission
  end
  
  # Retroactively compute the cost of this shipment
  def retro_estimate_cost_and_commissions
    self.cost = 0
    shipments.each do |shipment|
      self.cost += shipment.cost + shipment.diesel_fee
    end
    profit = amount - cost
    compute_commissions
    save
  end
  
  def n_packages
    shipments.map {|s| s.n_packages}.sum
  end
  
  def self.identify_economic_ids
    Invoice.where('economic_id IS NULL').each do |invoice|
      Economic.identify_booked_invoice invoice
    end
  end
  
  def self.fetch_economic_data
    Invoice.where('economic_id IS NOT NULL AND paid = 0').each do |invoice|
      data = Economic.get_invoice_data invoice
      if data['remainder'].to_f < 0.01
        invoice.paid = true
        invoice.save
      end
    end
  end

  def self.retro_estimate_costs_and_commissions
    Invoice.where('cost IS NULL').each do |invoice|
      invoice.retro_estimate_cost_and_commissions
    end
  end
end
