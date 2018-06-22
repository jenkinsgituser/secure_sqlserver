# SqlServerClient
# Class used to connect to, and query, Microsoft SQL Server databases.
# Attempted using PuppetX::Sqlserver::SqlConnection, but it doesn't return results.
#
# @return
#   Array[Hash] client.data
#   Array client.fields
# @example
#   sql = 'select * from sys.all_objects'
#   client = SqlServerClient.new
#   client.open
#   client.query(sql)
#   client.data
#   client.fields
#
require 'win32ole'

class SqlServerClient

  attr_reader :connection, :fields, :data

  def initialize
    @connection = nil
    @fields = nil
    @data = nil
  end

  CONNECTION_CLOSED = 0

  # using a method instead of hard coding enables testing outside of Windows
  def win32_exception
    ::WIN32OLERuntimeError
  end

  def open
    connect(default_connection_string)
  end

  def load(config)
    connect(connection_string(config))
  end

  def connect(connection_string)
    begin
      @connection = WIN32OLE.new('ADODB.Connection')
      @connection.Open(connection_string) unless open?
    rescue win32_exception => e
      Puppet.debug "sqlserver_client.rb error: connect(connection_string): #{e.message}"
    end
  end

  def default_connection_string
    #connection_string << "Persist Security Info=False;"
    connection_string =  'Provider=SQLOLEDB.1'
    connection_string << ';Integrated Security=SSPI'
    connection_string << ';Data Source='
    connection_string << '.'
    connection_string << ';Initial Catalog='
    connection_string << 'master'
    connection_string << ';Network Library=dbmssocn'
    Puppet.debug "connection_string=#{connection_string}"
    connection_string
  end

  def connection_string(config)
    params = {
      #'Provider'             => 'SQLOLEDB.1',
      'Provider'              => 'SQLNCLI11',
      'Integrated Security'   => 'SSPI',
      'Initial Catalog'       => config[:database] || 'master',
      'Data Source'           => '.',
      #'DataTypeComptibility'  => 80,
      #'Network Library'       => 'dbmssocn'
      #'Persist Security Info' => False
    }

    if config[:host] != nil && config[:host] !~ /^MSSQLSERVER$/
      #params['Data Source'] = ".\\#{config[:hostname]}"
      params['Data Source'] = config[:host]
    end

    connection_string = params.map { |k, v| "#{k}=#{v}" }.join(';')
    Puppet.debug "connection_string=#{connection_string}"
    connection_string
  end

  # This loads the query results into the Recordset object.
  # The Recordset object's GetRows method returns an array of columns
  # (not rows, as you might expect), so use the Ruby array's transpose method
  # to convert it to an array of rows:
  # data = recordset.GetRows.transpose
  #
  def query(sql)
    return nil if closed?
    @data = []
    begin
      recordset = WIN32OLE.new('ADODB.Recordset')
      recordset.Open(sql, @connection)
      unless empty?(recordset)
        # Create and populate an array of field names
        @fields = []
        recordset.Fields.each do |field|
          @fields << field.Name
        end
        recordset.MoveFirst
        @data = recordset.GetRows
        # An ADO Recordset's GetRows method returns an array of columns,
        # so we'll use the transpose method to convert it to an array of rows
        @data.transpose
      end
      recordset.Close
    rescue win32_exception => e
      @data = []
      Puppet.debug "sqlserver_client.rb error: query(sql): #{e.message}"
    end
    @data
  end

  def simple_array(sql)
    return nil if closed?
    @data = []
    begin
      recordset = WIN32OLE.new('ADODB.Recordset')
      recordset.Open(sql, @connection)
      #unless empty?(recordset)
        # Create and populate an array of field names
        @fields = []
        recordset.Fields.each do |field|
          @fields << field.Name
        end
        # Move to the first record/row, if any exist
        # rows.each { |datum| @data << datum }
        Puppet.debug "1. RecordCount = #{recordset.RecordCount}"
        recordset.MoveFirst
        Puppet.debug "2. #{emptyset}, RecordCount = #{recordset.RecordCount}"
        rows = recordset.GetRows
        Puppet.debug "3. #{emptyset}, RecordCount = #{recordset.RecordCount}"
        # An ADO Recordset's GetRows method returns an array of columns,
        # I want all the values of one column, so I will NOT transpose.
        #@data = @data.flatten
        @data = rows[0]
      #end
      recordset.Close
    rescue win32_exception => e
      @data = []
      Puppet.debug "sqlserver_client.rb error: query(sql): #{e.message}"
    end
    @data
  end

  def hasharray(sql)
    return nil if closed?
    @data = []
    begin
      recordset = WIN32OLE.new('ADODB.Recordset')
      recordset.Open(sql, @connection)
      unless empty?(recordset)
        # Create and populate an array of field names
        @fields = []
        recordset.Fields.each do |field|
          @fields << field.Name
        end
        recordset.MoveFirst
        rows = recordset.GetRows
        # An ADO Recordset's GetRows method returns an array
        # of columns, so we'll use the transpose method to
        # convert it to an array of rows
        @data = rows.transpose

        # return the data as an array of hashes keyed by the field names
        hash = []
        @data.size.times do |rowIndex|
          row = {}
          @fields.size.times { |i| row[@fields[i]] = @data[rowIndex][i] }
          hash << row
        end
        @data = hash

      end
      recordset.Close
    rescue win32_exception => e
      @data = []
      Puppet.debug "sqlserver_client.rb error: query(sql): #{e.message}"
    end
    @data
  end

  # use this method for ddl sql that don't return a resultset.
  #
  def execute(sql)
    return nil if closed?
    begin
      @connection.Execute(sql)
    rescue win32_exception => e
      Puppet.debug "sqlserver_client.rb error: exec(sql): #{e.message}"
    end
  end

  def empty?(recordset)
    begin
      emptyset = recordset.RecordCount != -1 || recordset.RecordCount != 0
      Puppet.debug "empty? = #{emptyset}, RecordCount = #{recordset.RecordCount}"
      recordset.RecordCount != -1 || recordset.RecordCount != 0
    rescue win32_exception => e
      Puppet.debug "sqlserver_client.rb error: empty?(): #{e.message}"
    end
  end

  def close
    begin
      @connection.Close unless closed?
    rescue win32_exception => e
      Puppet.debug "sqlserver_client.rb error: close(): #{e.message}"
    end
  end

  def closed?
    @connection.nil? || @connection.State == CONNECTION_CLOSED
  end

  def open?
    !@connection.nil? && @connection.State != CONNECTION_CLOSED
  end

  def error_messages
    return nil if @connection.nil? || @connection.Errors.count == 0
    error_count = @connection.Errors.count - 1
    ((0..error_count).map { |i| @connection.Errors(i).Description.to_s}).join("\n")
  end

  def errors?
    !@connection.nil? && @connection.Errors.count != 0
  end

  def error_count
    @connection.Errors.count
  end

end
