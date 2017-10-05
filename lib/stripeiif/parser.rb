require 'iif/parser'

module StripeIif
  class Parser
    def initialize(iif_data)
      @iif_parser = Iif::Parser.new(iif_data)
    end

    def parse
      @iif_parser.transactions.collect do |txn|
        txn.entries.collect { |entry| parse_entry(entry) }
      end.flatten.compact
    end

    def parse_entry(entry)
      case entry.trnstype
      when 'DEPOSIT'
        if entry.accnt == 'Stripe Account'
          return Entry.new(
            entry.date,
            :deposit,
            entry.amount,
            '',
            parse_memo(entry.memo),
            parse_ref(entry.memo))
        end
      when 'GENERAL JOURNAL'
        if entry.accnt == 'Stripe Sales' || entry.accnt == 'Stripe Returns'
          return Entry.new(
            entry.date,
            :sale,
            (entry.amount * -1),
            entry.name,
            parse_memo(entry.memo),
            parse_ref(entry.memo))
        end
        if entry.accnt == 'Stripe Payment Processing Fees'
          return Entry.new(
            entry.date,
            :fee,
            entry.amount * -1,
            'Stripe',
            "Fees for #{entry.date}")
        end
      else
        raise "Unknown transaction type #{entry.trnstype}"
      end
    end

    def parse_ref(memo)
      memo_pieces = split_memo(memo)
      if memo_pieces
        ref = memo_pieces[1]
      else
        ""
      end
    end

    def parse_memo(memo)
      memo_pieces = split_memo(memo)
      if memo_pieces
        memo_pieces[2]
      else
        memo
      end
    end

    protected

    # Charge ID: ch_1B7W80HVGziu7wpb0hjHEG4X | Honky Dory <> Green Bits: Non-Managed
    def split_memo(memo)
      memo_pieces = format_return_memo_if_needed(memo).split(/\:|\|/, 3)

      # Add optional 3rd element
      if memo_pieces.size == 2
        memo_pieces << ("")
      end

      if memo_pieces && memo_pieces.size == 3
        memo_pieces.collect { |memo| memo.strip }
      else
        nil
      end
    end

    def format_return_memo_if_needed(memo)
      if memo.start_with?("Refund of charge")
        memo.sub("Refund of charge ", "Refund of charge: ") + " | Refund of charge"
      else
        memo
      end
    end
  end
end
