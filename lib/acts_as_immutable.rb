# +---------------------------------------------------------------------------+
# | Acts As Immutable                                                         |
# +---------------------------------------------------------------------------+
# | A Rails plugin that will ensure an ActiveRecord object is immutable once  |
# | saved. Optionally, you can specify attributes to be mutable if the object |
# | is in a particular state (block evaluates to true).                       |
# +---------------------------------------------------------------------------+
# | Author: NuLayer Inc. / www.nulayer.com                                    |
# +---------------------------------------------------------------------------+

module ActsAsImmutable
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def acts_as_immutable(*mutable_attributes, &condition)
      if mutable_attributes.empty? && !condition.nil?
        raise StandardError, "the condition block requires a list of mutable attributes"
      end
      
      #init_hook_methods
      
      immutable_write_attributes(*mutable_attributes, &condition)
      clear_mutable_condition_after_save
    end
    
    
    private

      def immutable_write_attributes(*mutable_attributes, &condition)
        mutable_attributes = mutable_attributes.map(&:to_s)
        
        # Hook the write_attribute method which is used to set an attribute in ActiveRecord
        # to use our immutability check first
        hook_method(:write_attribute) do |attr_name, value|
          @mutable_condition ||= instance_eval(&condition) if !condition.nil?
          
          # Allow attributes to be written if they have not changed,
          # required when associations are saved but not changed
          value_changed = read_attribute(attr_name) != value
          
          if new_record? || !value_changed || (mutable_attributes.include?(attr_name) && @mutable_condition)
            _write_attribute(attr_name, value)
          else
            errors.add(attr_name, "is an immutable attribute")
            raise ActiveRecord::ActsAsImmutableError, attr_name
          end
        end
      end
      
      #def setup_hook_methods
      #  alias :_write_attribute :write_attribute
      #  alias :_after_save :after_save
      #end
      
      # Clear the mutable condition after a save
      def clear_mutable_condition_after_save
        hook_method(:after_save) do
          @mutable_condition = nil
          _after_save
        end
      end
      
      # Hook into a method by renaming the current method to _METHOD
      # and define the new method by a block
      def hook_method(method_name, &block)
        ub_original_method = instance_method(method_name)
        undef_method(method_name)
        define_method "_#{method_name}", ub_original_method
        define_method method_name, &block
      end

  end  
end

module ActiveRecord
  class ActsAsImmutableError < ActiveRecord::ActiveRecordError
    def initialize(attribute)
      super("#{attribute} is an immutable attribute")
    end
  end
end

ActiveRecord::Base.send :include, ActsAsImmutable
