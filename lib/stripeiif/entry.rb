module StripeIif
  class Entry
    attr_accessor :date, :type, :amount, :payee, :memo, :ref

    def initialize(date, type, amount, payee, memo, ref = '')
      @date = date
      @type = type
      @amount = amount
      @payee = payee
      @memo = memo
      @ref = ref
    end

    def merge(other_entry)
      if self.type != other_entry.type || self.date != other_entry.date
        raise "Unable to merge unlike type and dates for #{self} and #{other_entry}."
      end

      Entry.new(
        self.date,
        self.type,
        self.amount + other_entry.amount,
        self.payee,
        self.memo
      )
    end

    def to_a
      [@date, @amount.to_s('F'), @payee, @memo, @ref]
    end
  end
end
