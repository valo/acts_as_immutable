$:.unshift(File.dirname(__FILE__) + '/../')
$:.unshift(File.dirname(__FILE__) + '/../../lib')

require 'config'
require 'acts_as_immutable'

class ActsAsImmutableUsingVirtualField < ActiveRecord::TestCase
  class Payment < ActiveRecord::Base
    attr_accessor :record_locked
    acts_as_immutable(:status, :amount) do
      !record_locked
    end
    
    def after_initialize
      self.record_locked = true
    end
  end
  
  def test_creating_object_directly
    p = Payment.create!(:customer => "Valentin", :status => "success", :amount => 5.00)
    
    assert_raises ActiveRecord::ActsAsImmutableError do
      p.amount = 10.00
    end
    
    p.record_locked = false
    p.amount = 10.00
    p.record_locked = true
    assert p.save
    assert_equal 10.00, p.reload.amount
  end
  
  def test_creating_object_in_several_steps
    p = Payment.new(:customer => "Valentin", :status => "success", :amount => 5.00)
    
    assert p.save
    
    assert_raises ActiveRecord::ActsAsImmutableError do
      p.amount = 10.00
    end
    
    p.record_locked = false
    p.amount = 10.00
    assert p.save
    assert_equal 10.00, p.reload.amount
  end
  
  def test_writing_attributes_low_level
    p = Payment.create!(:customer => "Valentin", :status => "success", :amount => 5.00)
    
    p = Payment.find(p.id)
    p.record_locked = false
    p.amount = 10.00
    
    p = Payment.find(p.id)
    p.record_locked = false
    p[:amount] = 10.00
    
    p = Payment.find(p.id)
    p.record_locked = false
    p["amount"] = 10.00
    
    p = Payment.find(p.id)
    p.record_locked = false
    p.instance_eval do
      self.write_attribute("amount", 10)
    end
    
    p = Payment.find(p.id)
    p.record_locked = false
    p.instance_eval do
      self.write_attribute(:amount, 10)
    end
  end
end