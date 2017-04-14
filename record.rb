require 'active_support/inflector'
require './connection'

class Record
  def initialize(params = {})
    initialize_object(params)
  end

  class << self
    def create(params = {})
      self.new(params).save
    end

    def all
      Connection.execute(select_statement).to_a
    end

    def find(id)
      Connection.execute(find_statement(id)).first
    end

    def find_by(params)
      Connection.execute(find_by_statement(params)).first
    end

    def where(params)
      Connection.execute(where_statement(params)).to_a
    end

    def scope(name, query)
      define_singleton_method name do
        query.call
      end
    end
  end

  def save
    Connection.execute(save_statement)
  end

  private

  class << self
    def table_name
      self.name.underscore.pluralize
    end

    def find_statement(id)
      "#{select_statement} WHERE #{table_name}.id = #{id} LIMIT 1"
    end

    def select_statement
      "SELECT * FROM #{table_name}"
    end

    def find_by_statement(params)
      "#{select_statement} WHERE #{conditionals(params)} LIMIT 1"
    end

    def conditionals(params)
      return conditional(params.first) if params.size == 1

      params.map.with_index do |param, index|
        return "#{conditional(param)} AND" if index < params.size - 1
        "#{conditional(param)};"
      end.join(' ')
    end

    def conditional(param)
      "#{table_name}.#{param[0]} = '#{param[1]}'"
    end

    def where_statement(params)
      "#{select_statement} WHERE #{conditionals(params)}"
    end
  end

  def initialize_object(params)
    attributes.each do |attribute|
      self.class.__send__(:attr_accessor, attribute)
      self.send("#{attribute}=", params[attribute]) unless attribute == :id
    end
  end

  def attributes
    Connection.execute(attributes_statement).map do |attribute|
      attribute['column_name'].to_sym
    end
  end

  def attributes_statement
    "SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = '#{table_name}'"
  end

  def table_name
    class_name.pluralize
  end

  def class_name
    self.class.name.underscore
  end

  def save_statement
    "INSERT INTO #{table_name} (#{save_attributes}) VALUES (#{save_attribute_values})"
  end

  def save_attributes
    attributes.map do |attribute|
      attribute unless attribute == :id
    end.compact.join(', ')
  end

  def save_attribute_values
    attributes.map do |attribute|
      "'#{send(attribute)}'" unless attribute == :id
    end.compact.join(', ')
  end
end
