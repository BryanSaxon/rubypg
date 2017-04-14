require 'pg'

class Connection
  def self.execute(query)
    begin
      connection = PG::Connection.new(dbname: 'rubypg')
      connection.exec(query)
    rescue PG::Error => exception
      puts exception.message
    ensure
      connection.close
    end
  end
end
