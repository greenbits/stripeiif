module StripeIif
  class Statement
    def initialize(entries)
      @entries = entries
    end

    def merge_fees!
      entry_groups = @entries.group_by(&:type)
      merged_entries = entry_groups.collect do |entry_type, entry_group|
        if entry_type == :fee
          merge_entries_by_date(entry_group)
        else
          entry_group
        end
      end.flatten

      @entries = merged_entries
    end

    def to_a
      @entries.collect do |entry|
        entry.to_a
      end
    end

    protected

    def merge_entries_by_date(entries)
      entries.group_by(&:date).collect do |entry_date, entry_entries|
        zero_entry = StripeIif::Entry.new(
          entry_date,
          :fee,
          BigDecimal.new('0.00'),
          'Stripe',
          "Fees for #{entry_date}")

        entry_entries.inject(zero_entry) { |sum_entry, next_entry| sum_entry.merge(next_entry) }
      end
    end
  end
end
