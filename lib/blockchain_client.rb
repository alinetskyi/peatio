# encoding: UTF-8
# frozen_string_literal: true

module BlockchainClient
  Error                  = Class.new(StandardError) # TODO: Rename to Exception.
  ConnectionRefusedError = Class.new(StandardError) # TODO: Remove this.

  class << self
    #
    # Returns API client for given blockchain key.
    #
    # @param key [String, Symbol]
    #   The blockchain key.
    # @return [BaseAPI]
    def [](key)
      blockchain = Blockchain.find_by_key(key)
      if blockchain.try(:client).present?
        "BlockchainClient::#{blockchain.client.capitalize}"
      end.constantize.new(blockchain)
    end
  end

  class Base
    extend Memoist

    #
    # Returns the blockchain.
    #
    # @return [blockchain]
    attr_reader :blockchain

    def initialize(blockchain)
      @blockchain = blockchain
    end

    #
    # Returns hot wallet balance.
    #
    # @abstract Derived API clients must implement it.
    #
    # @param currency [String, Symbol]
    # @return [BigDecimal]
    def load_balance!(currency)
      method_not_implemented
    end

    #
    # Returns transaction details.
    #
    # TODO: Docs.
    #
    # @param txid [String]
    # @return [Hash]
    #   The deposit details.
    def load_deposit!(txid)
      method_not_implemented
    end

    #
    # Created new address.
    #
    # TODO: Doc.
    #
    def create_address!(options = {})
      method_not_implemented
    end

    #
    # Creates new withdrawal and returns transaction ID.
    #
    # TODO: Doc.
    #
    def create_withdrawal!(issuer, recipient, amount, options = {})
      method_not_implemented
    end

    # TODO: Doc.
    def inspect_address!(address)
      method_not_implemented
    end

    def convert_to_base_unit!(value)
      x = value.to_d * blockchain.base_factor
      unless (x % 1).zero?
        raise BlockchainClient::Error, "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " +
                              "#{value.to_d} - #{x.to_d} must be equal to zero."
      end
      x.to_i
    end

    def convert_from_base_unit(value, currency)
      value.to_d / currency.base_factor
    end

    def normalize_address(address)
      address.downcase
    end

    def normalize_txid(txid)
      txid.downcase
    end

    %i[ load_balance load_deposit create_address create_withdrawal inspect_address ].each do |method|
      class_eval <<-RUBY
        def #{method}(*args, &block)
          silencing_exception { #{method}!(*args, &block) }
        end
      RUBY
    end

  protected

    def silencing_exception
      yield
    rescue => e
      report_exception(e)
      nil
    end
  end
end
