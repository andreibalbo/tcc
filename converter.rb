require 'csv'
require 'json'
require 'pry-nav'

class Converter

  def self.csv_to_json(input, output)
    binding.pry
    data = File.open(input).read
    CSV.parse(data).to_json
  end

  def self.json_to_csv(input, output)

    hash = JSON.parse(input)

    # mexer

    data = File.save(output)

  end
end

# Converter.csv_to_json('teste.csv')
