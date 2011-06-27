require 'rubygems'
require 'google_spreadsheet'
require "./lib/to_google_spreadsheet/version"

# get the openstruct attribute hash
class OpenStruct
  def _hash
    @table
  end
end

module GoogleSpreadsheet
  class Spreadsheet
    def find_or_create_worksheet_by_name(name)
      worksheets.find {|ws| ws.title == name}
      ws ||= add_worksheet(name) # create it if it doesn't exists
      ws
    end
  end

  class Worksheet
    def set_header_columns(row)
      get_hash_from_row(row).keys.each_with_index do |key, col_nr|
        self[1, col_nr + 1] = key.to_s.capitalize
      end
    end

    def populate(rows)
      # TODO: Stop looping, put directly into the Google Spreadsheet hash
      # provided by the Gem
      # https://github.com/gimite/google-spreadsheet-ruby/blob/master/lib/google_spreadsheet.rb#L693-700
      rows.each_with_index do |row, row_nr|
        get_hash_from_row(row).each_with_index do |val, col_nr|
          self[row_nr + 2, col_nr + 1] = val.last
        end
      end
    end

    private
    def get_hash_from_row(row)
      return row.attributes if row.respond_to?(:attributes) # ar
      return row._hash if row.respond_to?(:_hash) # ostruct
      row # fallback to handle hashes
    end
  end
end

class Array
  include ToGoogleSpreadsheet

  def to_google_spreadsheet(worksheet, spreadsheet = nil)
    session = GoogleSpreadsheet.login(*CREDENTIALS)
    spreadsheet = session.spreadsheet_by_key(spreadsheet || DEFAULT_SPREADSHEET)
    @ws = spreadsheet.find_or_create_worksheet_by_name(worksheet)
    @ws.set_header_columns(self.first)
    @ws.populate(self)
    @ws.save
  end
end
